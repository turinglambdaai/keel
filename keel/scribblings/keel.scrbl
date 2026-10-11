#lang scribble/manual

@(require (for-label racket/base keel))

@title{Keel: Neutral Contracts for Racket Desktop Runtimes}

@defmodule[keel]

Keel defines a transport-neutral value codec, structured error shape,
schema vocabulary, and lifecycle vocabulary. It deliberately does not define
a renderer or protocol frame.

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

@section{Schemas}

A schema describes application messages without selecting their transport.
Rivet can map a command to an RVT1 RPC while Glaze maps it to a GLZ1 invoke.

@defproc[(make-app-schema [id string?]
                          [revision exact-nonnegative-integer?]
                          [#:records records list? null]
                          [#:enums enums list? null]
                          [#:commands commands list? null]
                          [#:events events list? null]
                          [#:states states list? null])
         app-schema?]{Validates references, uniqueness, type placement, and names, then returns a canonical schema.}
@defproc[(schema-type? [value any/c]) boolean?]{Recognizes scalar, list, map, optional, and named-reference type descriptors.}
@defproc[(app-schema->app-value [schema app-schema?]) app-value?]{Returns the normative introspection value for schema contract 1.}
@defproc[(encode-app-schema [schema app-schema?]) bytes?]{Canonically encodes the introspection value.}

The scalar descriptors are @racket[Null], @racket[Bool], @racket[Int64],
@racket[Float64], @racket[String], @racket[Bytes], @racket[Value],
@racket[Error], and @racket[Unit]. Compound descriptors use
@racket[list-type], @racket[map-type], @racket[optional-type], and
@racket[reference-type]. Definitions use @racket[schema-field],
@racket[schema-record], @racket[schema-enum], @racket[schema-parameter],
@racket[schema-command], @racket[schema-event], and @racket[schema-state].

@section{Lifecycle}

@defproc[(lifecycle-state? [value any/c]) boolean?]{Recognizes @racket['starting], @racket['ready], @racket['running], @racket['stopping], and @racket['stopped].}
@defproc[(lifecycle-transition? [from lifecycle-state?] [to lifecycle-state?]) boolean?]{Reports whether the transition is part of the shared lifecycle contract.}
@defproc[(request-terminal-outcome? [value any/c]) boolean?]{Recognizes the mutually exclusive request outcomes.}
