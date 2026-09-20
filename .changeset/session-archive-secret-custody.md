---
"@germ-network/atprotooauth": minor
---

Rework the session-archive secret custody onto oauth4swift's own zeroizing
custody (germ-network/oauth4swift#68).

`OAuth.SessionState.Archive` now holds its secrets — the DPoP P-256 scalar and
the access/refresh token values — as `@SecretField` `SecretBytes`, so
`AtprotoOAuthAgent.Archive.session` carries them directly and
`AtprotoOAuthAgent.Archive` encodes **only** through `swift-secret-bytes`'
`SecretArchive` (`try SecretArchive(encoding: archive)` /
`.decode(Archive.self)`); any other coder throws rather than writing a private
scalar or a token plainly.

This replaces the earlier `AtprotoOAuthAgent.SessionArchive` mirror (and its
`SessionArchiveMappingError`), which existed only because oauth4swift carried
its secrets as plain `Codable` — it is now unnecessary.

**Breaking:** the platform floor rises to iOS 18 (swift-secret-bytes 0.5.0 and
oauth4swift both floor there), and `AtprotoOAuthAgent.Archive.init(did:session:)`
is no longer `throws` — it stores the (already-secret-bearing) oauth4swift
archive directly.
