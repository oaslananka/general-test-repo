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
| Groq GPT-OSS-120B | PASS + coding PASS | Free Tier; forced only, because a Groq key may belong to a paid Developer account |
| OpenRouter `openrouter/free` | PASS | explicit free router |
| LLM7 anonymous `default` | PASS | keyless/free |
| OVHcloud anonymous Qwen3-Coder | PASS + coding PASS | keyless/free |
| Pollinations legacy `openai-fast` | PASS smoke | keyless legacy endpoint; coding test pending |
| Gemini 3.8 Flash | disabled by default | current project returned HTTP 402; only test with explicit free-only guard |
| Ollama | host-dependent | local inference; no third-party inference charge |

Real issue → agent → edit → test → PR runs have succeeded independently through Kilo authenticated, Kilo anonymous, NVIDIA NIM, Groq, OpenRouter Free, LLM7 anonymous and OVHcloud anonymous. Each test fixed only the intentional challenge implementation and passed 3/3 tests.

## Zero-cost automatic fallback

Default order:

```text
kilo
→ kiloanon
→ nvidia
→ openrouter
→ ovh
→ llm7
→ pollinations
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
- `FREEINFERENCE_API_KEY` — no-card FreeInference account; pinned to free `glm-5.3-flash`
- `REQUESTY_API_KEY` — Requesty Free plan; pinned to the $0 NVIDIA endpoint

Guard variables:

- `GEMINI_FREE_ONLY=true` — only after confirming the Google project cannot bill.
- `CLOUDFLARE_FREE_ONLY=true` — only on a Workers Free account / hard-stop setup.
- `MISTRAL_FREE_ONLY=true` — only on Mistral's no-card Free plan.

## Keyless providers

No repository secret is required for:

- Kilo anonymous Auto Free
- LLM7 anonymous `default`
- OVHcloud AI Endpoints anonymous Qwen3-Coder
- Pollinations legacy `openai-fast`

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
pollinations
freeinference
cohere
requesty
ollama
```

This mode is for proving that a single provider can actually inspect files, edit code, run tests and produce a pull request without falling through to another provider.


## Verification levels

- **PASS + coding PASS**: real inference plus a forced single-provider issue → edit → tests → PR run succeeded.
- **PASS smoke**: real inference succeeded through OpenCode; coding-agent challenge still needs to be forced once.
- **pending key**: config is present, but the repository does not yet have the provider key.
- **excluded**: researched but intentionally not enabled because of billing risk, terms, or unreliable CI behavior.

Current pending-key routes:

- FreeInference — no card; free models include GLM 5.3 Flash, DeepSeek V4 Flash, Qwen3.6 and others.
- Cohere North Mini Code — model itself is free until rate limits for trial and production keys.
- Requesty Free — no card; 200 requests/day on its free models; config is pinned to a zero-priced NVIDIA endpoint.
- Hetzner experimental inference — free while the experiment runs.
- Aion Free Tier.
- Inception Mercury free allocation.
- Cloudflare Workers AI — guarded; enable only on a Workers Free/hard-stop account.
- Mistral Free — guarded; enable only on a no-card Free plan.

Excluded from CI/default:

- uncloseai — public endpoint was live but its current served model did not match reliably in OpenCode smoke; removed rather than keeping a flaky route.
- VLM Run anonymous — repeated OpenCode transport failures.
- OpenCode Zen paid-capable gateway — free models exist, but billing/auto-reload makes it unsuitable for a strict never-pay default.
- SambaNova Cloud — current plan page requires adding a payment method and purchasing credits before first requests.
- Freebuff — genuinely free local CLI, but its current Terms require human-present sessions and prohibit headless/bot automation, so it is not used in GitHub Actions.

### Freebuff for local interactive use only

```bash
npm install -g freebuff
cd your-repository
freebuff
```

Do not place Freebuff in this repository's headless GitHub Actions workflow.

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
- FreeInference: https://freeinference.org and https://doc.freeinference.org/models
- Cohere North Mini Code: https://docs.cohere.com/docs/north-mini-code-1.0
- Requesty Free: https://www.requesty.ai/pricing and https://www.requesty.ai/models/free
- Freebuff terms: https://freebuff.com/terms-of-service
