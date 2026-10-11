# Contributing

App Core is intentionally small. Changes should make independent Racket
desktop runtimes more interoperable without coupling their UI or transport
architectures.

Before opening a pull request:

1. Run `raco test -p racket-app-core` from a linked package installation.
2. Run `raco setup --doc-index --check-pkg-deps --pkgs racket-app-core`.
3. Update documentation and rejection tests with behavior changes.
4. Never edit an existing golden vector silently. Explain compatibility impact,
   add cross-runtime evidence, and state whether negotiation or a new contract
   version is required.

Pull requests should be narrow, include an executable regression test, and
avoid transport-, renderer-, or product-specific policy. Generated files and
unrelated formatting changes do not belong in the same commit.

By participating, contributors agree to be respectful, technically specific,
and welcoming. Maintainers may moderate conduct that makes collaboration unsafe
or hostile.
