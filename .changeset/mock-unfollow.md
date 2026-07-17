---
"@germ-network/atprotooauth": minor
---

Add `MockAtmosphere.unfollow(subjectDid:from:)` — mirrors `follow`/`block`, delegating to `MockPDS.unfollow`. Lets tests undo a follow to construct a "not followed" social-graph state. Requires AtprotoClient 0.7.0 (the release that adds `unfollow`); the dependency floor is bumped to `from: "0.7.0"`.
