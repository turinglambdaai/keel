#lang racket/base

(provide lifecycle-state?
         lifecycle-states
         lifecycle-initial-state
         lifecycle-terminal-state?
         lifecycle-transition?
         request-terminal-outcome?
         request-terminal-outcomes)

(define lifecycle-states '(starting ready running stopping stopped))
(define lifecycle-initial-state 'starting)

(define (lifecycle-state? value)
  (and (symbol? value) (memq value lifecycle-states) #t))

(define (lifecycle-terminal-state? value)
  (eq? value 'stopped))

(define allowed-transitions
  (hash 'starting '(ready stopping)
        'ready '(running stopping)
        'running '(stopping)
        'stopping '(stopped)
        'stopped '()))

(define (lifecycle-transition? from to)
  (and (lifecycle-state? from)
       (lifecycle-state? to)
       (memq to (hash-ref allowed-transitions from))
       #t))

;; Cancellation is an intent, not a second terminal response. Once an accepted
;; request owns one of these outcomes, later completion/cancel races are no-ops.
(define request-terminal-outcomes '(succeeded failed cancelled timed-out))

(define (request-terminal-outcome? value)
  (and (symbol? value) (memq value request-terminal-outcomes) #t))
