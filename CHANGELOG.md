# @germ-network/atprotooauth

## 0.4.1

### Patch Changes

- [#46](https://github.com/germ-network/AtprotoOAuth/pull/46) [`4e491db`](https://github.com/germ-network/AtprotoOAuth/commit/4e491dbd76c5bf5962c4cb05333bc5d9c2ffa939) Thanks [@germ-mark](https://github.com/germ-mark)! - check for handle with at:// prefix when confirming handle

## 0.4.0

### Minor Changes

- [#44](https://github.com/germ-network/AtprotoOAuth/pull/44) [`e7ec3af`](https://github.com/germ-network/AtprotoOAuth/commit/e7ec3afd3486abde0134faf8ae8d3500302373ca) Thanks [@germ-mark](https://github.com/germ-mark)! - \* adopt refresh changes in oauth4Swift, consuming an optional saved state, changing our refreshed(tokenState:) api to take an optional parameter.
  - expose an api to merge session archive state

## 0.3.0

### Minor Changes

- [#37](https://github.com/germ-network/AtprotoOAuth/pull/37) [`68b0610`](https://github.com/germ-network/AtprotoOAuth/commit/68b061099f94febd8340c584631b6805f4ec3699) Thanks [@anna-germ](https://github.com/anna-germ)! - Get rid of AtprotoOAuthAgent's lazyIssuer
  Make convenience function on Atproto.Resolver that combines getAuthorizationServerURL with initial identity resolution logic

### Patch Changes

- [#41](https://github.com/germ-network/AtprotoOAuth/pull/41) [`80712a6`](https://github.com/germ-network/AtprotoOAuth/commit/80712a6f6d21f80971403628380828914d09db78) Thanks [@germ-mark](https://github.com/germ-mark)! - adopt a Fallback resolver that combines two resolvers in serial

- [#37](https://github.com/germ-network/AtprotoOAuth/pull/37) [`4a45b28`](https://github.com/germ-network/AtprotoOAuth/commit/4a45b2879af2d86edcbe2f6fc914637c11821764) Thanks [@anna-germ](https://github.com/anna-germ)! - Fix implementation of getAuthorizationURL

## 0.2.1

### Patch Changes

- [#39](https://github.com/germ-network/AtprotoOAuth/pull/39) [`fda8080`](https://github.com/germ-network/AtprotoOAuth/commit/fda8080ba4cae5a61fe4af45e1189acb65b82c04) Thanks [@germ-mark](https://github.com/germ-mark)! - adopt atprotoTypes 0.3.0

## 0.2.0

### Minor Changes

- [#34](https://github.com/germ-network/AtprotoOAuth/pull/34) [`d46bfb8`](https://github.com/germ-network/AtprotoOAuth/commit/d46bfb83eacae1acb8c48905a1ad05977c3afe04) Thanks [@germ-mark](https://github.com/germ-mark)! - Contain the .authorize and .restore parameters in a Client struct

## 0.1.1

### Patch Changes

- [#31](https://github.com/germ-network/AtprotoOAuth/pull/31) [`bf6555e`](https://github.com/germ-network/AtprotoOAuth/commit/bf6555e47b815cfc6ccd4361621101e8a14cf956) Thanks [@anna-germ](https://github.com/anna-germ)! - Use new protocols from AtprotoClient

## 0.1.0

### Minor Changes

- [#27](https://github.com/germ-network/AtprotoOAuth/pull/27) [`5bff861`](https://github.com/germ-network/AtprotoOAuth/commit/5bff861814b113fa024292236a271758decc2b6f) Thanks [@germ-mark](https://github.com/germ-mark)! - This implements correct proxying to the Bluesky appview, adopting
  upstream client interface changes

- [#25](https://github.com/germ-network/AtprotoOAuth/pull/25) [`f9cb9e1`](https://github.com/germ-network/AtprotoOAuth/commit/f9cb9e164aff7c6ff957fcf83f69316079fb272e) Thanks [@germ-mark](https://github.com/germ-mark)! - Adopt GermConvenience that uses [swift http types](https://github.com/apple/swift-http-types)

  The atproto client is in the process of rework, so we commented out the current usage of unauthenticated client in the demo

### Patch Changes

- [#24](https://github.com/germ-network/AtprotoOAuth/pull/24) [`9410a77`](https://github.com/germ-network/AtprotoOAuth/commit/9410a77a2e34016b7068bb4bb64d28621d3b8dd9) Thanks [@germ-mark](https://github.com/germ-mark)! - fix SwiftUI modifiers to be conditional for macOS

- [#25](https://github.com/germ-network/AtprotoOAuth/pull/25) [`feb350d`](https://github.com/germ-network/AtprotoOAuth/commit/feb350d5b349d9693076bbbf89871629d1f24ce0) Thanks [@germ-mark](https://github.com/germ-mark)! - Adopt the change in oauth4swift for token validator to return a boolean, though we throw instead of returning false and don't yet handle getting a different did than we started with (we throw in this case)
