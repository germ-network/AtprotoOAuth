# @germ-network/atprotooauth

## 0.1.0

### Minor Changes

- [#27](https://github.com/germ-network/AtprotoOAuth/pull/27) [`5bff861`](https://github.com/germ-network/AtprotoOAuth/commit/5bff861814b113fa024292236a271758decc2b6f) Thanks [@germ-mark](https://github.com/germ-mark)! - This implements correct proxying to the Bluesky appview, adopting
  upstream client interface changes

- [#25](https://github.com/germ-network/AtprotoOAuth/pull/25) [`f9cb9e1`](https://github.com/germ-network/AtprotoOAuth/commit/f9cb9e164aff7c6ff957fcf83f69316079fb272e) Thanks [@germ-mark](https://github.com/germ-mark)! - Adopt GermConvenience that uses [swift http types](https://github.com/apple/swift-http-types)

  The atproto client is in the process of rework, so we commented out the current usage of unauthenticated client in the demo

### Patch Changes

- [#24](https://github.com/germ-network/AtprotoOAuth/pull/24) [`9410a77`](https://github.com/germ-network/AtprotoOAuth/commit/9410a77a2e34016b7068bb4bb64d28621d3b8dd9) Thanks [@germ-mark](https://github.com/germ-mark)! - fix SwiftUI modifiers to be conditional for macOS

- [#25](https://github.com/germ-network/AtprotoOAuth/pull/25) [`feb350d`](https://github.com/germ-network/AtprotoOAuth/commit/feb350d5b349d9693076bbbf89871629d1f24ce0) Thanks [@germ-mark](https://github.com/germ-mark)! - Adopt the change in oauth4swift for token validator to return a boolean, though we throw instead of returning false and don't yet handle getting a different did than we started with (we throw in this case)
