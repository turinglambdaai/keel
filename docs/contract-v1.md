# App Core Contract v1

This document is normative for the version-1 value and lifecycle contracts.
The Racket implementation and `tests/golden-v1.txt` are executable evidence.

## Scope

App Core sits above a byte stream and below an application protocol. It owns
values, errors, lifecycle names, cancellation terminality, canonical encoding,
and resource limits. It does not own a frame header, request identifier,
streaming/backpressure mechanism, renderer, permission model, or installer.

## Canonical values

All integer fields are little-endian. Lengths and collection counts are
unsigned 32-bit values. Values use one byte tag followed by the listed body.

| Tag | Value | Body |
|---:|---|---|
| `00` | Null | none |
| `01` | False | none |
| `02` | True | none |
| `03` | Int64 | signed two's-complement 64-bit integer |
| `04` | String | byte length + well-formed UTF-8 |
| `05` | Bytes | byte length + uninterpreted bytes |
| `06` | List | item count + encoded values |
| `07` | Float64 | finite IEEE-754 binary64 bits |
| `08` | Map | entry count + String key/value pairs |
| `09` | Error | String code + String message + data value |

Map keys are ordered by their encoded UTF-8 bytes in strictly increasing
lexicographic order. A decoder rejects duplicates and any other order. Map
keys are encoded as ordinary String values and count toward node/depth budgets.

Float64 preserves finite IEEE-754 bits, including the sign of zero. NaN and
positive/negative infinity are not values in v1 because JSON transports cannot
round-trip them portably.

Error codes match `[a-z][a-z0-9]*(-[a-z0-9]+)*`. App Core does not define a
closed list: RVT1, GLZ1, and future transports each publish and negotiate their
own taxonomy. Error messages are safe for users and logs; protocols must not
substitute raw exception text. Error data may be any App Core value.

## Budgets and rejection

- maximum encoded value: 64 MiB
- maximum container nesting: 64
- maximum decoded/encoded value nodes: 262,144

Decoders reject unknown tags, malformed/truncated lengths, invalid UTF-8,
non-finite Float64, non-String Map keys, non-canonical Map order, invalid Error
shapes, budget overflow, and trailing bytes. Encoders reject mutable maps,
improper/cyclic lists, unsupported values, and the same budget violations.

## Lifecycle

The shared vocabulary is `starting -> ready -> running -> stopping -> stopped`.
Early shutdown may move `starting` or `ready` directly to `stopping`. `stopped`
is terminal; restart policy belongs to the embedding runtime.

For accepted requests, success, failure, cancellation, and timeout are mutually
exclusive terminal outcomes. Cancellation is an intent that races completion;
the winner owns the single terminal result, and later attempts are no-ops.

## Evolution

Existing tags and golden bytes never change within v1. An additive tag still
requires protocol negotiation because an older decoder must reject it. Any
change to numeric representation, canonical ordering, budgets, or structured
error shape requires a new App Core contract version and migration evidence.
