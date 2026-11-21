---
"@germ-network/atprotooauth": minor
---

Send the DID as `login_hint` for an `AuthIdentity.did` identity, even when a handle is also given. The handle was preferred only because the Bluesky sign-in page displayed a raw DID (bluesky-social/atproto#4900), which is fixed. A `.handle` identity still sends the handle.
