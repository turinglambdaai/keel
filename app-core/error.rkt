#lang racket/base

(provide app-error?
         app-error-code
         app-error-message
         app-error-data
         app-error-code?
         make-app-error)

;; Error codes are transport-neutral kebab-case tokens. Each protocol owns its
;; closed taxonomy; the shared value layer only guarantees a portable shape.
(define error-code-rx #px"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")

(define (app-error-code? value)
  (and (string? value) (regexp-match-exact? error-code-rx value) #t))

(struct app-error (code message data)
  #:transparent
  #:constructor-name make-unchecked-app-error)

(define (make-app-error code message [data (void)])
  (unless (app-error-code? code)
    (raise-argument-error 'make-app-error "app-error-code?" code))
  (unless (string? message)
    (raise-argument-error 'make-app-error "string?" message))
  (make-unchecked-app-error code message data))
