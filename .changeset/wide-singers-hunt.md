---
"@germ-network/atprotooauth": minor
---

Adopt GermConvenience that uses [swift http types](https://github.com/apple/swift-http-types)

The atproto client is in the process of rework, so we commented out the current usage of unauthenticated client in the demo

we also adopt the change in oauth4swift for token validator to return a boolean, though we throw instead of returning false and don't yet handle getting a different did than we started with (we throw in this case)