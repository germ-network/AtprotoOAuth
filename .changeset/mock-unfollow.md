---
"@germ-network/atprotooauth": minor
---

Add `MockAtmosphere.unfollow(subjectDid:from:)` — mirrors `follow`/`block`, delegating to `MockPDS.unfollow`. Lets tests undo a follow to construct a "not followed" social-graph state. Requires the AtprotoClient release that adds `unfollow`; bump the AtprotoClient pin to that version.
