# @germ-network/atprotooauth

## 0.5.8

### Patch Changes

- [#68](https://github.com/germ-network/AtprotoOAuth/pull/68) [`340a330`](https://github.com/germ-network/AtprotoOAuth/commit/340a330380b8a3a63442419e4af16b47b29bc066) Thanks [@anna-germ](https://github.com/anna-germ)! - Add known followers and relationships to demo app

- [#70](https://github.com/germ-network/AtprotoOAuth/pull/70) [`b9e7192`](https://github.com/germ-network/AtprotoOAuth/commit/b9e7192761fe70b9024e19d62066d5a2b7696ffb) Thanks [@germ-mark](https://github.com/germ-mark)! - add parameter (with default value) on atprotoOauthAgent.refresh to specify a debounce interval

- [#67](https://github.com/germ-network/AtprotoOAuth/pull/67) [`a902bef`](https://github.com/germ-network/AtprotoOAuth/commit/a902befa08a00ac7c556c9fa9b4fea4212f2c598) Thanks [@germ-mark](https://github.com/germ-mark)! - Validate the did's issuer

## 0.5.7

### Patch Changes

- [#65](https://github.com/germ-network/AtprotoOAuth/pull/65) [`20a7c39`](https://github.com/germ-network/AtprotoOAuth/commit/20a7c39844145e0f67005ece073f19d6337f8264) Thanks [@germ-mark](https://github.com/germ-mark)! - add mock atmosphere implementation of getrelationship

## 0.5.6

### Patch Changes

- [#63](https://github.com/germ-network/AtprotoOAuth/pull/63) [`80c06bb`](https://github.com/germ-network/AtprotoOAuth/commit/80c06bb3cb85aecc6cc33e052fdcaa7037e235ff) Thanks [@germ-mark](https://github.com/germ-mark)! - properly include base64 in mock target

## 0.5.5

### Patch Changes

- [#61](https://github.com/germ-network/AtprotoOAuth/pull/61) [`c26844b`](https://github.com/germ-network/AtprotoOAuth/commit/c26844b5679ee4a4c38869256fca306877150e47) Thanks [@germ-mark](https://github.com/germ-mark)! - use patched oauth4swift for base64/base64url confusion

## 0.5.4

### Patch Changes

- [#59](https://github.com/germ-network/AtprotoOAuth/pull/59) [`4f848c9`](https://github.com/germ-network/AtprotoOAuth/commit/4f848c963879c0a615e18139c06d1c666095e8ab) Thanks [@germ-mark](https://github.com/germ-mark)! - adopt upstream changes to HTTP API

## 0.5.3

### Patch Changes

- [#57](https://github.com/germ-network/AtprotoOAuth/pull/57) [`722ce4e`](https://github.com/germ-network/AtprotoOAuth/commit/722ce4eba00b11738d89010442b014fc96f43be5) Thanks [@germ-mark](https://github.com/germ-mark)! - add mockAmosphere handling of public service getProfile

- [#57](https://github.com/germ-network/AtprotoOAuth/pull/57) [`4bab357`](https://github.com/germ-network/AtprotoOAuth/commit/4bab3576be466486c502bcae910bff73f44292a4) Thanks [@germ-mark](https://github.com/germ-mark)! - don't use non-reserved domain in mock atmosphere, separate out various flavors of getProfile

## 0.5.2

### Patch Changes

- [#55](https://github.com/germ-network/AtprotoOAuth/pull/55) [`211e4aa`](https://github.com/germ-network/AtprotoOAuth/commit/211e4aac14520bcda782dbf62322b713e8e5ad23) Thanks [@germ-mark](https://github.com/germ-mark)! - add dependencies to Mocks targets to fix issues when building in an xcodeproj

## 0.5.1

### Patch Changes

- [#51](https://github.com/germ-network/AtprotoOAuth/pull/51) [`4f82073`](https://github.com/germ-network/AtprotoOAuth/commit/4f82073768b7060a96d381a6e7992d208f89cdb7) Thanks [@germ-mark](https://github.com/germ-mark)! - adopt handle verification

## 0.5.0

### Minor Changes

- [#49](https://github.com/germ-network/AtprotoOAuth/pull/49) [`a958f42`](https://github.com/germ-network/AtprotoOAuth/commit/a958f42110cde8c56db88db4caff24a85e4ae69a) Thanks [@germ-mark](https://github.com/germ-mark)! - Adopt test renaming, mock target pattern, and add a Mock Atmosphere

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
