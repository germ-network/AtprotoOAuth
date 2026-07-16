---
"@germ-network/atprotooauth": minor
---

Add `MockAtmosphere.unfollow(subjectDid:from:)` — mirrors `follow`/`block`, delegating to `MockPDS.unfollow`. Lets tests undo a follow to construct a "not followed" social-graph state. The AtprotoClient dependency is temporarily pinned to the merge commit that adds `unfollow` because the automated release is blocked upstream; convert it back to a `from:` version pin once AtprotoClient cuts that release.
