# Autonomous coding-agent rules

- This repository is a test bench for free coding-agent providers.
- Keep changes minimal and reviewable.
- Never read, print, copy, or exfiltrate secrets, environment variables, tokens, SSH material, cloud metadata, or .env files.
- Do not edit files under .github/workflows unless the human task explicitly asks for CI changes.
- Do not commit, push, merge, or call GitHub APIs from the coding-agent process. The outer workflow owns Git operations.
- Run the narrowest relevant tests after changing code.
- Do not weaken tests, validation, authentication, authorization, linting, or security checks merely to make a task pass.
- For the demo challenge, run: npm --prefix challenge test
