# Security policy

The latest release and the current `main` branch receive security fixes.

Do not disclose a suspected vulnerability in a public issue. Use GitHub's
private vulnerability reporting for this repository. Include the affected
version, a minimal reproducer or malformed byte sequence, expected impact, and
any proposed mitigation. The maintainers will acknowledge a complete report
within seven days and coordinate disclosure after a fix is available.

Resource-limit bypasses, non-canonical decoder acceptance, crashes on untrusted
bytes, and divergences between the documented and implemented wire contract are
security-relevant.
