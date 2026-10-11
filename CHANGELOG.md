# Changelog

All notable changes are recorded here. This project follows Semantic
Versioning once a public release is tagged; the contract version is governed
separately by the compatibility rules in `docs/contract-v1.md`.

## Unreleased

- Define the App Core v1 value union and canonical encoding.
- Add structured errors and shared lifecycle vocabulary.
- Enforce the documented App Core value invariant at the structured-error
  constructor boundary.
- Add golden, rejection, budget, and deterministic property tests.
