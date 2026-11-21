---
"@germ-network/atprotooauth": patch
---

Send the `state` parameter on the authorization request, as the AT Protocol OAuth profile requires. oauth4swift only generates `state` when the server lacks S256 PKCE, so it was never sent; `authorize()` now generates a fresh random value per call, which the callback is checked against.
