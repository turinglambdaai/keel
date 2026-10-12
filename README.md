# keel

`keel` is the transport-neutral application contract shared by
Racket desktop runtimes. It gives native-rendered and WebView-rendered stacks
one small value model, one canonical byte encoding, one structured-error shape,
one lifecycle vocabulary, one transport-neutral schema vocabulary, and one
compatibility corpus.

The package intentionally does **not** own UI controls, transport frames,
process embedding, HTTP, WebView messaging, or platform policy. Rivet keeps
RVT1 and its WinUI 3 / SwiftUI-AppKit / GTK4 hosts; Glaze keeps GLZ1 and its
native WebView adapters.

## Contract v1

The value union is:

- Null, Bool, signed Int64, finite Float64, UTF-8 String, Bytes
- List and immutable Map with String keys
- structured Error: kebab-case code, human-safe message, optional data value

Encoding is canonical. Existing RVT1 scalar/list tags remain byte-identical;
Float64, Map, and Error append new tags. Map keys are ordered by their UTF-8
bytes, non-finite floats are rejected, duplicate/non-canonical keys are rejected
on decode, and every implementation enforces the same 64 MiB, depth-64, and
262,144-node budgets. See [the normative contract](docs/contract-v1.md).

```racket
#lang racket/base

(require keel)

(define payload
  (hash "task" "review"
        "progress" 0.5
        "tags" (list "racket" "desktop")))

(define wire (encode-app-value payload))
(decode-app-value wire)

(make-app-error "invalid-args" "Expected a non-empty title"
                (hash "field" "title"))
```

Schemas describe the application boundary without prescribing its transport:

```racket
(define Task
  (schema-record 'Task
                 (list (schema-field 'id Int64)
                       (schema-field 'title String))))

(define task-schema
  (make-app-schema
   "org.racket.taskboard" 1
   #:records (list Task)
   #:commands
   (list (schema-command 'create-task
                         (list (schema-parameter 'title String))
                         (reference-type 'Task)
                         '("invalid-args")))))

(encode-app-schema task-schema)
```

Rivet may map a command to an RVT1 RPC while Glaze maps it to a GLZ1 invoke;
the schema does not own either envelope. Schema names preserve ordinary Racket
conventions such as `ready?`, `save!`, and `string->bytes`, plus Unicode;
consumer code generators own collision-checked source-language identifiers.

## Compatibility discipline

`tests/golden-v1.txt` is the normative byte corpus. Changing an existing line
is a compatibility break. New union members require a written rationale, new
cross-runtime golden vectors, decoder budget tests, and a version decision.
Transport protocols may embed this codec, but they must negotiate their own
versions and error taxonomies.

## Development

```sh
raco pkg install --auto --name keel --link
raco test -p keel
```

The package supports Racket 9.0 and newer and is MIT licensed.

Compatibility changes follow the review gates in
[CONTRIBUTING.md](CONTRIBUTING.md). Please report suspected vulnerabilities
through the private process in [SECURITY.md](SECURITY.md).
