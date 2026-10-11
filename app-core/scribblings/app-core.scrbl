#lang scribble/manual

@(require (for-label racket/base app-core))

@title{App Core: Neutral Contracts for Racket Desktop Runtimes}

@defmodule[app-core]

App Core defines a transport-neutral value codec, structured error shape, and
lifecycle vocabulary. It deliberately does not define a renderer or protocol
frame.

@section{Values}

@defthing[app-null void?]{The canonical Null value.}
@defproc[(app-null? [value any/c]) boolean?]{Recognizes Null.}
@defproc[(app-value? [value any/c]) boolean?]{Recognizes values encodable by v1.}
@defproc[(encode-app-value [value app-value?]) bytes?]{Encodes one canonical value.}
@defproc[(decode-app-value [encoded bytes?]) app-value?]{Decodes exactly one canonical value and rejects trailing bytes.}

@defthing[max-encoded-value-size exact-positive-integer?]{The 64 MiB byte budget.}
@defthing[max-value-depth exact-positive-integer?]{The maximum container nesting depth.}
@defthing[max-value-nodes exact-positive-integer?]{The aggregate value-node budget.}

@section{Structured errors}

@defproc[(make-app-error [code app-error-code?]
                         [message string?]
                         [data app-value? app-null])
         app-error?]{Constructs a transport-neutral error value.}
@defproc[(app-error-code? [value any/c]) boolean?]{Recognizes portable kebab-case error tokens.}

@section{Lifecycle}

@defproc[(lifecycle-state? [value any/c]) boolean?]{Recognizes @racket['starting], @racket['ready], @racket['running], @racket['stopping], and @racket['stopped].}
@defproc[(lifecycle-transition? [from lifecycle-state?] [to lifecycle-state?]) boolean?]{Reports whether the transition is part of the shared lifecycle contract.}
@defproc[(request-terminal-outcome? [value any/c]) boolean?]{Recognizes the mutually exclusive request outcomes.}
