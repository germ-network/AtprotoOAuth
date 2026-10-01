---
"@germ-network/atprotooauth": patch
---

Require AtprotoClient 0.12.0 and GermConvenience 0.14.0, and depend on `GermConvenienceURLSession` from the tests that use `URLSession`. A `URLSession` conforms to `HTTPFetcher` from that product, so callers passing one as `authFetcher` add it.
