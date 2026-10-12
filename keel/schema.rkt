#lang racket/base

(require racket/list
         racket/string
         "error.rkt"
         "value.rkt")

(provide (struct-out scalar-type)
         (struct-out list-type)
         (struct-out map-type)
         (struct-out optional-type)
         (struct-out reference-type)
         Null
         Bool
         Int64
         Float64
         String
         Bytes
         Value
         Error
         Unit
         schema-type?
         schema-name?
         (struct-out schema-field)
         (struct-out schema-record)
         (struct-out schema-enum)
         (struct-out schema-parameter)
         (struct-out schema-command)
         (struct-out schema-event)
         (struct-out schema-state)
         make-app-schema
         app-schema?
         app-schema-id
         app-schema-revision
         app-schema-records
         app-schema-enums
         app-schema-commands
         app-schema-events
         app-schema-states
         schema-type->app-value
         app-schema->app-value
         encode-app-schema)

;; The schema layer names application messages without naming a transport.
;; Rivet maps command/event/state descriptors to RVT1. Glaze can map the same
;; descriptors to GLZ1 without either protocol depending on the other.

(define schema-id-rx #px"^[A-Za-z0-9][A-Za-z0-9._-]*$")
(define max-schema-revision (sub1 (expt 2 63)))
(define max-schema-name-bytes 255)

(define (safe-schema-name-string? value)
  ;; Schema names are wire identities, not identifiers in one consumer's
  ;; implementation language. Preserve normal Racket names (`ready?`,
  ;; `save!`, `string->bytes`) and Unicode instead of lossy sanitization;
  ;; native/JS code generators remain responsible for collision-checked local
  ;; identifiers. Bound the UTF-8 form and reject invisible control/format
  ;; characters so names stay safe to display and diagnose.
  (and (positive? (string-length value))
       (<= (string-utf-8-length value) max-schema-name-bytes)
       (for/and ([character (in-string value)])
         (not (memq (char-general-category character) '(cc cf cs))))))

(define (schema-name? value)
  (and (or (string? value) (symbol? value))
       (safe-schema-name-string? (if (symbol? value)
                                     (symbol->string value)
                                     value))
       #t))

(define (normalize-name who value)
  (unless (schema-name? value)
    (raise-argument-error who "schema-name?" value))
  (if (symbol? value) (symbol->string value) value))

(define scalar-names '(Null Bool Int64 Float64 String Bytes Value Error Unit))

(struct scalar-type (name)
  #:transparent
  #:guard
  (lambda (name who)
    (unless (memq name scalar-names)
      (raise-argument-error who
                            "(or/c 'Null 'Bool 'Int64 'Float64 'String 'Bytes 'Value 'Error 'Unit)"
                            name))
    name))

(define Null (scalar-type 'Null))
(define Bool (scalar-type 'Bool))
(define Int64 (scalar-type 'Int64))
(define Float64 (scalar-type 'Float64))
(define String (scalar-type 'String))
(define Bytes (scalar-type 'Bytes))
(define Value (scalar-type 'Value))
(define Error (scalar-type 'Error))
(define Unit (scalar-type 'Unit))

(define (schema-type? value)
  (or (scalar-type? value)
      (and (list-type? value) (schema-type? (list-type-element value)))
      (and (map-type? value) (schema-type? (map-type-value value)))
      (and (optional-type? value) (schema-type? (optional-type-element value)))
      (reference-type? value)))

(define (guard-type who value)
  (unless (schema-type? value)
    (raise-argument-error who "schema-type?" value))
  value)

(struct list-type (element)
  #:transparent
  #:guard (lambda (element who) (guard-type who element)))

(struct map-type (value)
  #:transparent
  #:guard (lambda (value who) (guard-type who value)))

(struct optional-type (element)
  #:transparent
  #:guard
  (lambda (element who)
    (guard-type who element)
    (when (equal? element Unit)
      (raise-arguments-error who "Unit cannot be optional" "element" element))
    element))

(struct reference-type (name)
  #:transparent
  #:guard (lambda (name who) (normalize-name who name)))

(struct schema-field (name type)
  #:transparent
  #:guard
  (lambda (name type who)
    (values (normalize-name who name) (guard-type who type))))

(struct schema-record (name fields)
  #:transparent
  #:guard
  (lambda (name fields who)
    (unless (and (list? fields) (andmap schema-field? fields))
      (raise-argument-error who "(listof schema-field?)" fields))
    (ensure-unique-names who "field" fields schema-field-name)
    (values (normalize-name who name) fields)))

(struct schema-enum (name cases)
  #:transparent
  #:guard
  (lambda (name cases who)
    (unless (and (list? cases) (pair? cases) (andmap schema-name? cases))
      (raise-argument-error who "non-empty (listof schema-name?)" cases))
    (define normalized (map (lambda (case) (normalize-name who case)) cases))
    (ensure-unique-strings who "enum case" normalized)
    (values (normalize-name who name) normalized)))

(struct schema-parameter (name type)
  #:transparent
  #:guard
  (lambda (name type who)
    (values (normalize-name who name) (guard-type who type))))

(struct schema-command (name parameters result error-codes)
  #:transparent
  #:guard
  (lambda (name parameters result error-codes who)
    (unless (and (list? parameters) (andmap schema-parameter? parameters))
      (raise-argument-error who "(listof schema-parameter?)" parameters))
    (ensure-unique-names who "parameter" parameters schema-parameter-name)
    (guard-type who result)
    (unless (and (list? error-codes) (andmap app-error-code? error-codes))
      (raise-argument-error who "(listof app-error-code?)" error-codes))
    (ensure-unique-strings who "error code" error-codes)
    (values (normalize-name who name) parameters result error-codes)))

(struct schema-event (name type)
  #:transparent
  #:guard
  (lambda (name type who)
    (values (normalize-name who name) (guard-type who type))))

(struct schema-state (name type)
  #:transparent
  #:guard
  (lambda (name type who)
    (values (normalize-name who name) (guard-type who type))))

(struct app-schema (id revision records enums commands events states)
  #:transparent
  #:constructor-name make-unchecked-app-schema)

(define (ensure-unique-strings who kind names)
  (define seen (make-hash))
  (for ([name (in-list names)])
    (when (hash-ref seen name #f)
      (raise-arguments-error who
                             (format "duplicate ~a name" kind)
                             "name" name))
    (hash-set! seen name #t)))

(define (ensure-unique-names who kind values name-of)
  (ensure-unique-strings who kind (map name-of values)))

(define (type-has-unit? type)
  (cond
    [(scalar-type? type) (equal? type Unit)]
    [(list-type? type) (type-has-unit? (list-type-element type))]
    [(map-type? type) (type-has-unit? (map-type-value type))]
    [(optional-type? type) (type-has-unit? (optional-type-element type))]
    [else #f]))

(define (type-references type)
  (cond
    [(reference-type? type) (list (reference-type-name type))]
    [(list-type? type) (type-references (list-type-element type))]
    [(map-type? type) (type-references (map-type-value type))]
    [(optional-type? type) (type-references (optional-type-element type))]
    [else '()]))

(define (check-payload-type who label type known-names)
  (when (type-has-unit? type)
    (raise-arguments-error who
                           "Unit is valid only as a command result"
                           "location" label
                           "type" type))
  (for ([name (in-list (type-references type))])
    (unless (hash-ref known-names name #f)
      (raise-arguments-error who
                             "schema type references an unknown record or enum"
                             "location" label
                             "reference" name))))

(define (sort-by-name values name-of)
  (sort values string<? #:key name-of))

(define (make-app-schema id
                         revision
                         #:records [records '()]
                         #:enums [enums '()]
                         #:commands [commands '()]
                         #:events [events '()]
                         #:states [states '()])
  (define who 'make-app-schema)
  (unless (and (string? id) (regexp-match-exact? schema-id-rx id))
    (raise-argument-error who "portable schema id string" id))
  (unless (and (exact-nonnegative-integer? revision)
               (<= revision max-schema-revision))
    (raise-argument-error who "signed 64-bit exact-nonnegative-integer?" revision))
  (for ([values+predicate+label
         (in-list (list (list records schema-record? "records")
                        (list enums schema-enum? "enums")
                        (list commands schema-command? "commands")
                        (list events schema-event? "events")
                        (list states schema-state? "states")))])
    (define values (car values+predicate+label))
    (define predicate (cadr values+predicate+label))
    (define label (caddr values+predicate+label))
    (unless (and (list? values) (andmap predicate values))
      (raise-argument-error who (format "(listof ~a?)" label) values)))
  (ensure-unique-names who "record" records schema-record-name)
  (ensure-unique-names who "enum" enums schema-enum-name)
  (ensure-unique-names who "command" commands schema-command-name)
  (ensure-unique-names who "event" events schema-event-name)
  (ensure-unique-names who "state" states schema-state-name)
  (ensure-unique-strings who
                         "named type"
                         (append (map schema-record-name records)
                                 (map schema-enum-name enums)))
  (define known-names
    (for/hash ([name (in-list (append (map schema-record-name records)
                                     (map schema-enum-name enums)))])
      (values name #t)))
  (for ([record (in-list records)])
    (for ([field (in-list (schema-record-fields record))])
      (check-payload-type who
                          (format "record ~a field ~a"
                                  (schema-record-name record)
                                  (schema-field-name field))
                          (schema-field-type field)
                          known-names)))
  (for ([command (in-list commands)])
    (for ([parameter (in-list (schema-command-parameters command))])
      (check-payload-type who
                          (format "command ~a parameter ~a"
                                  (schema-command-name command)
                                  (schema-parameter-name parameter))
                          (schema-parameter-type parameter)
                          known-names))
    (unless (equal? (schema-command-result command) Unit)
      (check-payload-type who
                          (format "command ~a result" (schema-command-name command))
                          (schema-command-result command)
                          known-names)))
  (for ([event (in-list events)])
    (check-payload-type who
                        (format "event ~a" (schema-event-name event))
                        (schema-event-type event)
                        known-names))
  (for ([state (in-list states)])
    (check-payload-type who
                        (format "state ~a" (schema-state-name state))
                        (schema-state-type state)
                        known-names))
  (make-unchecked-app-schema
   id
   revision
   (sort-by-name records schema-record-name)
   (sort-by-name enums schema-enum-name)
   (sort-by-name commands schema-command-name)
   (sort-by-name events schema-event-name)
   (sort-by-name states schema-state-name)))

(define (schema-type->app-value type)
  (unless (schema-type? type)
    (raise-argument-error 'schema-type->app-value "schema-type?" type))
  (cond
    [(scalar-type? type)
     (hash "kind" "scalar" "name" (symbol->string (scalar-type-name type)))]
    [(list-type? type)
     (hash "kind" "list" "element" (schema-type->app-value (list-type-element type)))]
    [(map-type? type)
     (hash "kind" "map" "value" (schema-type->app-value (map-type-value type)))]
    [(optional-type? type)
     (hash "kind" "optional" "element" (schema-type->app-value (optional-type-element type)))]
    [else
     (hash "kind" "reference" "name" (reference-type-name type))]))

(define (field->value field)
  (hash "name" (schema-field-name field)
        "type" (schema-type->app-value (schema-field-type field))))

(define (app-schema->app-value schema)
  (unless (app-schema? schema)
    (raise-argument-error 'app-schema->app-value "app-schema?" schema))
  (hash
   "contract" 1
   "id" (app-schema-id schema)
   "revision" (app-schema-revision schema)
   "records"
   (for/list ([record (in-list (app-schema-records schema))])
     (hash "name" (schema-record-name record)
           "fields" (map field->value (schema-record-fields record))))
   "enums"
   (for/list ([enum (in-list (app-schema-enums schema))])
     (hash "name" (schema-enum-name enum)
           "cases" (schema-enum-cases enum)))
   "commands"
   (for/list ([command (in-list (app-schema-commands schema))])
     (hash "name" (schema-command-name command)
           "parameters"
           (for/list ([parameter (in-list (schema-command-parameters command))])
             (hash "name" (schema-parameter-name parameter)
                   "type" (schema-type->app-value (schema-parameter-type parameter))))
           "result" (schema-type->app-value (schema-command-result command))
           "errors" (schema-command-error-codes command)))
   "events"
   (for/list ([event (in-list (app-schema-events schema))])
     (hash "name" (schema-event-name event)
           "type" (schema-type->app-value (schema-event-type event))))
   "states"
   (for/list ([state (in-list (app-schema-states schema))])
     (hash "name" (schema-state-name state)
           "type" (schema-type->app-value (schema-state-type state))))))

(define (encode-app-schema schema)
  (encode-app-value (app-schema->app-value schema)))
