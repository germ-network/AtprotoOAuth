---
"@germ-network/atprotooauth": patch
---

Adopt the change in oauth4swift for token validator to return a boolean, though we throw instead of returning false and don't yet handle getting a different did than we started with (we throw in this case)
