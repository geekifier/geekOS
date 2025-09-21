---
applyTo: ".github/workflows/*.yaml"
---

Ignore linter warnings of "context access may be invalid" for references to env.VAR_NAME. Linter cannot detect variables set by redirect into GITHUB_ENV file.