# Contributing

Keel is intentionally small. Changes should make independent Racket
desktop runtimes more interoperable without coupling their UI or transport
architectures.

Before opening a pull request:

1. Run `raco test -p keel` from a linked package installation.
2. Run `raco setup --doc-index --check-pkg-deps --pkgs keel`.
3. Update documentation and rejection tests with behavior changes.
4. Never edit an existing golden vector silently. Explain compatibility impact,
   add cross-runtime evidence, and state whether negotiation or a new contract
   version is required.

The `app-schema->app-value` shape is a compatibility surface too. Renaming a
key, changing declaration-order semantics, or reinterpreting an existing type
descriptor requires the same written version decision as changing value bytes.

Pull requests should be narrow, include an executable regression test, and
avoid transport-, renderer-, or product-specific policy. Generated files and
unrelated formatting changes do not belong in the same commit.

## Family operating model

This document is the maintainer-facing coordination owner for Keel, Rivet,
Glaze, and Permit. It defines how the repositories compose; each repository's
own plan remains the only owner of its active implementation queue.

One application target normally chooses one presentation framework and may add
Permit as a sibling dependency:

```text
                         product
                    /       |       \
             Rivet or Glaze |      Permit (optional)
                    \       |       /
                     product policy

             Rivet --------> Keel <-------- Glaze
             Permit has no framework or Keel dependency
```

The dependency arrows are also ownership boundaries:

| Repository | Owns | Current outcome | Must not absorb |
| --- | --- | --- | --- |
| Keel | Canonical values, encoding, structured errors, lifecycle names, schema vocabulary, and cross-runtime corpus | Keep Contract v1 small and prove every change in both framework consumers | Transport frames, UI, permissions, packaging, or commercial policy |
| Rivet | First-party native hosts, RVT1, embedding, native system/distribution services, and mobile companion/runtime work | Close the desktop gates and advance mobile only through the evidence sequence in its active plan | WebView application semantics or product entitlements |
| Glaze | Native WebView hosts, GLZ1, web resource delivery, capability enforcement, and web-frontend tooling | Reach 1.0 by making native transport, curated APIs, schema governance, and three-platform release evidence agree | Native-control abstraction or product entitlements |
| Permit | Framework-neutral signed commercial rights, verification, policy evaluation, and issuer tooling | Earn the next release through security review, independent conformance, and real product integration evidence | UI/runtime services, update signing, payment, accounts, or hosted management |

Detailed work stays with its local owner:

- Rivet: `docs/desktop-closeout-mobile-plan.md`
- Glaze: `docs/1.0-plan.md`
- Permit: `ROADMAP.md`
- Keel wire semantics: `docs/contract-v1.md`

Route a proposed change to the lowest owner that can express it without
knowing a renderer, carrier, product, or business model. In particular:

1. A value, schema, lifecycle, or structured-error change starts in Keel.
2. RVT1, native controls, embedding, device communication, and native host
   lifecycle stay in Rivet.
3. GLZ1, WebView resource/message transport, frontend bindings, and browser
   development adapters stay in Glaze.
4. Entitlement, activation, trial, seat, subscription, and credential semantics
   stay in Permit; payment and account systems stay outside all four cores.
5. Product-specific workflow and policy stay in the product until repeated use
   proves a framework-neutral contract.

Do not land a coordinated contract change as simultaneous speculative edits.
Change and release the upstream owner first, run its complete gates, then run
the downstream compatibility suites, adapt consumers one at a time, and raise
each consumer's package floor only after its suite covers that version.
Development follows the latest published family packages; release builds pin
the versions they ship. A red consumer or family-compatibility run stops new
feature work until it is fixed forward or the upstream release is corrected.

The evidence chain for a family change is:

```text
owner tests + normative text
          -> published upstream package
          -> Rivet and Glaze latest-package suites
          -> affected product schema/build/package checks
          -> platform release evidence
```

Permit releases independently because its trust domain and protocol are
orthogonal to Keel. Composition is proven in product acceptance tests, never by
adding a framework dependency. Update signing, Permit credential signing, and
OS publisher signing always use separate keys and rotation procedures.

## Releasing

1. Bump the package version in `info.rkt` and add the matching
   `CHANGELOG.md` section in the same change.
2. Tag the release with an annotated tag.
3. Trigger the downstream compatibility suites the same day so contract
   changes are validated against consumers immediately instead of at their
   next update:

       gh workflow run family-compat.yml -R turinglambdaai/rivet
       gh workflow run family-compat.yml -R turinglambdaai/glaze

4. Watch both runs; a red downstream run outranks new work.

By participating, contributors agree to be respectful, technically specific,
and welcoming. Maintainers may moderate conduct that makes collaboration unsafe
or hostile.
