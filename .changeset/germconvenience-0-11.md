---
"@germ-network/atprotooauth": patch
---

Require GermConvenience 0.11.0, whose `URLSession.manualRedirect()` (the recommended `authFetcher`) also refuses redirects on Linux and Android.
