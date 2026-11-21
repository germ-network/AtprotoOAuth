---
"@germ-network/atprotooauth": minor
---

`MockAtmosphere` serves OAuth through the `MockAS` that each `MockPDS` now has (germ-network/AtprotoClient#74), so tests can script and inspect authorization server endpoints such as PAR. `createEntryway(serviceUrl:)` adds an authorization server on its own host with `Entryway.createDid(handle:)` putting DIDs behind it, `authorizationServer(for:)` returns a DID's `MockAS`, and `mockClient(userAuthenticator:)` takes a custom authenticator. A DPoP proof without an `Authorization` header is now treated as unauthenticated rather than rejected.
