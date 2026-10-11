#lang info

(define collection 'multi)
(define version "0.1")
(define pkg-desc "Transport-neutral application contracts for Racket desktop runtimes")
(define pkg-authors '(turinglambdaai))
(define license 'MIT)

(define deps '(["base" #:version "9.0"]))
(define build-deps '("racket-doc" "rackunit-lib" "scribble-lib"))

(define scribblings
  '(("app-core/scribblings/app-core.scrbl" () (library))))
