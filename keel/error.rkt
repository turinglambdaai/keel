#lang racket/base

(provide app-error?
         app-error-code
         app-error-message
         app-error-data
         app-error-code?)

;; Error codes are transport-neutral kebab-case tokens. Each protocol owns its
;; closed taxonomy; the shared value layer only guarantees a portable shape.
(define error-code-rx #px"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")

(define (app-error-code? value)
  (and (string? value) (regexp-match-exact? error-code-rx value) #t))

(struct app-error (code message data)
  #:transparent
  #:constructor-name make-unchecked-app-error)

;; Only the value layer can validate error data without introducing a module
;; cycle. Keep the unchecked constructor in a private submodule so users cannot
;; create a value that fails Keel's own documented invariant.
(module* private #f
  (provide make-unchecked-app-error))
