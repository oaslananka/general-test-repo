# general-test-repo — zero-cost AI coding test bench

This repository tests coding-agent providers from CLI and GitHub Actions with a strict goal: **no automatic paid fallback**.

## Verified on 2026-09-22

Real GitHub-hosted Actions inference tests:

| Route | Result | Cost safety |
|---|---|---|
| OpenCode V2 config | PASS | local CLI |
| Kilo `kilo-auto/free` via OpenCode | PASS | explicit free selector |
| Kilo CLI `kilo run --auto --model kilo/kilo-auto/free` | PASS | explicit free selector |
| Kilo anonymous Auto Free | PASS | keyless/free |
| NVIDIA NIM Nemotron 3 Super | PASS | hosted free prototype endpoint |
| Groq GPT-OSS-120B | PASS | Free Tier; **not in automatic zero-cost fallback** |
| OpenRouter `openrouter/free` | PASS | explicit free router |
| LLM7 anonymous `default` | PASS | keyless/free |
| OVHcloud anonymous Qwen3-Coder | PASS | keyless/free |
| Gemini 3.8 Flash | disabled by default | current project returned HTTP 402; only test with explicit free-only guard |
| Ollama | host-dependent | local inference; no third-party inference charge |

A real end-to-end issue → agent → edit → test → PR run has already succeeded through Kilo Auto Free.

## Zero-cost automatic fallback

Default order:

```text
kilo
→ kiloanon
→ nvidia
→ openrouter
→ ovh
→ llm7
→ ollama
```

The default chain intentionally excludes Gemini, Groq, Mistral, Cloudflare, Cohere, Inception, Hetzner and Aion. Those may have free plans/allocations, but their account state or terms are not equivalent to an explicit free model selector or keyless endpoint.

Override only if you deliberately want to:

```text
AI_PROVIDER_ORDER=kilo,kiloanon,nvidia,openrouter,ovh,llm7,ollama
```

## Provider secrets already supported

Core:

- `KILO_API_KEY`
- `NVIDIA_API_KEY`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`
- `GEMINI_API_KEY`

Optional free/no-card evaluation paths:

- `COHERE_API_KEY`
- `INCEPTION_API_KEY`
- `HETZNER_VLLM_API_KEY`
- `AION_API_KEY`
- `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID`
- `MISTRAL_API_KEY`

Guard variables:

- `GEMINI_FREE_ONLY=true` — only after confirming the Google project cannot bill.
- `CLOUDFLARE_FREE_ONLY=true` — only on a Workers Free account / hard-stop setup.
- `MISTRAL_FREE_ONLY=true` — only on Mistral's no-card Free plan.

## Keyless providers

No repository secret is required for:

- Kilo anonymous Auto Free
- LLM7 anonymous `default`
- OVHcloud AI Endpoints anonymous Qwen3-Coder

These are exercised automatically in provider smoke tests.

## Smoke test

**Actions → Free Provider Smoke Test → Run workflow**

The workflow:

1. installs current OpenCode + Kilo CLI,
2. parses the OpenCode V2 config,
3. confirms the challenge starts broken,
4. performs real inference calls,
5. treats free-tier HTTP 429 as a rate-limit condition rather than a false integration failure,
6. skips optional providers when their key/free-only guard is absent.

## Coding-agent test

Create an issue and use:

```text
/fix Fix the bug in challenge so that npm --prefix challenge test passes. Do not change the tests.
```

Automatic zero-cost fallback is used.

### Force one provider

Use:

```text
/provider ovh Fix the bug in challenge so that npm --prefix challenge test passes. Do not change the tests.
```

Supported forced provider names:

```text
kilo
nvidia
groq
openrouter
kiloanon
llm7
ovh
ollama
```

This mode is for proving that a single provider can actually inspect files, edit code, run tests and produce a pull request without falling through to another provider.

## Security

- Only repository OWNER / MEMBER / COLLABORATOR issue comments can trigger the agent.
- PR-comment triggers are intentionally disabled.
- Checkout uses `persist-credentials: false`.
- The model process does not receive Git push credentials.
- GitHub credentials are injected only after the agent finishes, for the PR/comment steps.
- Agent permissions deny workflow edits, `git push`, `git commit` and `gh`.
- Hosted free providers may have different prompt-retention terms. Use self-hosted Ollama for confidential source code.
- Generated PRs require human review; nothing auto-merges.

## Test challenge

`challenge/` contains one intentional percentage-calculation bug. A successful coding provider should modify only:

```text
challenge/src/discount.js
```

and make:

```bash
npm --prefix challenge test
```

pass 3/3 tests without editing the tests.

## Current documentation checked

- OpenCode V2 CLI: https://opencode.ai/v2/docs/cli/commands/
- OpenCode V2 providers: https://opencode.ai/v2/docs/providers
- Kilo CLI: https://kilo.ai/docs/code-with-ai/platforms/cli
- Kilo Auto Free: https://kilo.ai/docs/code-with-ai/agents/auto-model
- NVIDIA NIM: https://developer.nvidia.com/nim
- Groq limits: https://console.groq.com/docs/rate-limits
- OpenRouter Free Router: https://openrouter.ai/openrouter/free/
- Hetzner OpenCode integration: https://community.hetzner.com/tutorials/opencode-with-hetzner-inference-api-systemd-sandbox/
- Aion Labs free-tier limits: https://www.aionlabs.ai/docs/rate-limits/
