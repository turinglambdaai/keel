# Changelog

All notable changes are recorded here. This project follows Semantic
Versioning once a public release is tagged; the contract version is governed
separately by the compatibility rules in `docs/contract-v1.md`.

## 0.3.1 - 2026-10-12

- Make schema names transport identities rather than ASCII source-language
  identifiers: preserve Racket `?`, `!`, `->`, spaces, and Unicode, with a
  255-byte UTF-8 bound and rejection of control, format, and surrogate code
  points. Consumer code generators continue to own collision-checked local
  identifiers.

## 0.3.0 - 2026-10-11

- Rename the package and collection to `keel` (was `racket-app-core` /
  `app-core`). The repository renames with it; GitHub redirects the old
  URL. No consumers exist yet, so this is the cheapest possible moment —
  the value contract, tags, golden corpus, and schema vocabulary are
  unchanged.

## 0.2.0 - 2026-10-11

- Add a transport-neutral schema contract for scalar and compound types,
  records, enums, commands, events, and states, with validated references and
  deterministic Keel encoding.

## 0.1.0 - 2026-10-11

- Define the Keel v1 value union and canonical encoding.
- Add structured errors and shared lifecycle vocabulary.
- Enforce the documented Keel value invariant at the structured-error
  constructor boundary.
- Add golden, rejection, budget, and deterministic property tests.
