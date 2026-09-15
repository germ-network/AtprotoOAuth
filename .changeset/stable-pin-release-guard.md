---
---

CI/release-tooling only — adds a release-time guard (`scripts/check-stable-pins.swift`,
run in the Release workflow before publish) that refuses to cut a tag whose
`Package.swift` carries a `branch:`/`revision:` dependency pin. No package change,
so no release.
