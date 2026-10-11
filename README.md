# racket-app-core

`racket-app-core` is the transport-neutral application contract shared by
Racket desktop runtimes. It gives native-rendered and WebView-rendered stacks
one small value model, one canonical byte encoding, one structured-error shape,
one lifecycle vocabulary, and one compatibility corpus.

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

(require app-core)

(define payload
  (hash "task" "review"
        "progress" 0.5
        "tags" (list "racket" "desktop")))

(define wire (encode-app-value payload))
(decode-app-value wire)

(make-app-error "invalid-args" "Expected a non-empty title"
                (hash "field" "title"))
```

## Compatibility discipline

`tests/golden-v1.txt` is the normative byte corpus. Changing an existing line
is a compatibility break. New union members require a written rationale, new
cross-runtime golden vectors, decoder budget tests, and a version decision.
Transport protocols may embed this codec, but they must negotiate their own
versions and error taxonomies.

## Development

```sh
raco pkg install --auto --name racket-app-core --link
raco test -p racket-app-core
```

The package supports Racket 9.0 and newer and is MIT licensed.

Compatibility changes follow the review gates in
[CONTRIBUTING.md](CONTRIBUTING.md). Please report suspected vulnerabilities
through the private process in [SECURITY.md](SECURITY.md).
