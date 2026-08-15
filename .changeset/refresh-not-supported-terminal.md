---
"@germ-network/atprotooauth": patch
---

Handle `OAuth.Errors.refreshNotSupported` distinctly in `AtprotoOAuthAgent.startRefresh`: a valid access token preserves the session as before, but an expired one now transitions to `.expired` and emits `.loggedOut` instead of returning a stale token forever
