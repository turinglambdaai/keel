# Changelog

All notable changes are recorded here. This project follows Semantic
Versioning once a public release is tagged; the contract version is governed
separately by the compatibility rules in `docs/contract-v1.md`.

## 0.2.0 - 2026-10-11

- Add a transport-neutral schema contract for scalar and compound types,
  records, enums, commands, events, and states, with validated references and
  deterministic App Core encoding.

## 0.1.0 - 2026-10-11

- Define the App Core v1 value union and canonical encoding.
- Add structured errors and shared lifecycle vocabulary.
- Enforce the documented App Core value invariant at the structured-error
  constructor boundary.
- Add golden, rejection, budget, and deterministic property tests.
