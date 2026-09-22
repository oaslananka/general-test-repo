# general-test-repo — Free AI coding stack test bench

This repository tests zero-cost / free-tier coding-agent paths from both CLI and GitHub Actions.

## Included providers

1. **Gemini 3.8 Flash** — Gemini Developer API Free Tier.
2. **Kilo Auto Free** — `kilo-auto/free`, tested both through the OpenAI-compatible gateway and direct `kilo run --auto`.
3. **NVIDIA NIM** — `nvidia/nemotron-3-super-120b-a12b` free prototype endpoint.
4. **Groq** — `openai/gpt-oss-120b` on the Groq Free Tier.
5. **OpenRouter** — `openrouter/free`, a router restricted to free models.
6. **Ollama** — local/self-hosted fallback, no third-party inference charge.

OpenCode V2 is the common coding-agent harness. Kilo CLI is installed and smoke-tested independently too.

## Required GitHub Actions secrets

Go to **Settings → Secrets and variables → Actions** and add the providers you want to test:

- `GEMINI_API_KEY`
- `KILO_API_KEY`
- `NVIDIA_API_KEY`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`

The GitHub connector used to install this setup cannot read or write repository secrets, so these keys must be added from GitHub Settings.

## Optional Actions variables

- `AI_PROVIDER_ORDER` — default: `gemini,kilo,nvidia,groq,openrouter,ollama`
- `AI_RUNNER` — default: `ubuntu-latest`; set to `self-hosted` for Ollama.
- `AI_OLLAMA_MODEL` — default: `qwen3-coder:30b`

## Smoke test

Run **Actions → Free Provider Smoke Test → Run workflow**.

The smoke workflow:
- verifies current OpenCode and Kilo CLI installation,
- parses the OpenCode V2 configuration,
- confirms the intentionally broken challenge currently fails,
- makes a minimal real inference call through every provider whose secret is present,
- runs Kilo both via OpenCode-compatible gateway config and direct `kilo run --auto`,
- skips providers whose secret is absent,
- detects Ollama automatically on self-hosted runners.

Use `strict=true` to fail the workflow when any configured provider fails.

## Coding-agent test

Once this setup is on the default branch, create an issue and comment as repository owner/collaborator:

```text
/fix Fix the bug in challenge so that npm --prefix challenge test passes. Do not change the tests.
```

The agent tries providers in the configured order, modifies the checkout, verifies the test, and the outer workflow creates a pull request.

Other commands:

```text
/implement <task>
/review <task>
/ai <task>
```

Only OWNER / MEMBER / COLLABORATOR issue comments can trigger the agent.

## Security choices

- `actions/checkout` uses `persist-credentials: false`; the agent does not inherit Git push credentials.
- The GitHub token is only supplied later to the PR/comment step.
- OpenCode is denied edits to `.github/workflows/*` during normal agent runs.
- OpenCode is denied `git push`, `git commit`, and `gh` shell commands.
- Pull-request comments are intentionally not used as agent triggers in this starter.
- Provider keys are present in the agent process environment when that provider is used; do not treat hosted-agent execution as a hard secret-isolation boundary.
- Free hosted providers may log prompts/outputs; use local Ollama for confidential code.

## First verified GitHub Actions run

The initial push smoke run succeeded on GitHub-hosted Ubuntu 24.04 with:

- OpenCode `v2.0.14`
- Kilo CLI `7.7.7`
- Node.js `v24.20.0`
- npm `11.19.0`
- OpenCode V2 config parsing: PASS
- intentional challenge failure: confirmed
- provider inference calls: skipped because no provider secrets were present

## Current docs checked on 2026-09-22

- OpenCode V2 CLI: https://opencode.ai/v2/docs/cli/commands/
- OpenCode V2 providers: https://opencode.ai/v2/docs/providers
- OpenCode V2 permissions: https://opencode.ai/v2/docs/permissions
- Kilo CLI: https://kilo.ai/docs/code-with-ai/platforms/cli
- Kilo Gateway: https://kilo.ai/docs/gateway
- Gemini pricing: https://ai.google.dev/gemini-api/docs/pricing
- NVIDIA NIM model: https://build.nvidia.com/nvidia/nemotron-3-super-120b-a12b
- Groq limits: https://console.groq.com/docs/rate-limits
- OpenRouter Free Router: https://openrouter.ai/openrouter/free/
