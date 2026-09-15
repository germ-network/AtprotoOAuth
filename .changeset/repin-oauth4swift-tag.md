---
"@germ-network/atprotooauth": patch
---

Re-pin `oauth4swift` to its 0.7.0 release, replacing the temporary
revision pin the GermConvenienceHTTP-adoption fix (#84) shipped with —
0.7.0 didn't exist yet at the time. A revision-pinned dependency also
blocks this package from being consumed as a stable version by anything
that itself needs a stable pin (SwiftPM refuses to resolve a
stable-versioned package that transitively depends on an unstable one).
