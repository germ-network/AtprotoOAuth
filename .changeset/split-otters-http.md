---
"@germ-network/atprotooauth": patch
---

Fix build against GermConvenience 0.8.0, which split `HTTPFetcher` and
`HTTPDataResponse` out of the base `GermConvenience` library into a new
`GermConvenienceHTTP` product. Adds the `GermConvenienceHTTP` product
dependency to both targets and the matching import everywhere those types
are used, and raises the floor to `from: "0.8.0"`.

No public API change — this only restores buildability against current
GermConvenience releases.
