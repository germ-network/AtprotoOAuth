---
"@germ-network/atprotooauth": minor
---

Require oauth4swift 0.10 and discover through `OAuth.discoverProtectedResource` and `OAuth.discoverAuthorizationServer` (germ-network/oauth4swift#87). The metadata's `resource` and `issuer` must now be identical to the expected identifier, so a DID document whose PDS endpoint has a trailing slash or path, for a PDS publishing its bare origin, now fails discovery.
