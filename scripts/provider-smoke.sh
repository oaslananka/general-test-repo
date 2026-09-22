#!/usr/bin/env bash
set -euo pipefail

STRICT="${STRICT_PROVIDER_SMOKE:-false}"
FAILURES=0
TESTED=0
SUMMARY="${GITHUB_STEP_SUMMARY:-/tmp/provider-summary.md}"

pass() {
  printf '✅ %s\n' "$1"
  printf '| %s | PASS |\n' "$1" >> "$SUMMARY"
}

skip() {
  printf '⏭️  %s: %s\n' "$1" "$2"
  printf '| %s | SKIP — %s |\n' "$1" "$2" >> "$SUMMARY"
}

fail() {
  printf '❌ %s\n' "$1"
  printf '| %s | FAIL |\n' "$1" >> "$SUMMARY"
  FAILURES=$((FAILURES + 1))
}

run_model() {
  local label="$1"
  local model="$2"
  TESTED=$((TESTED + 1))

  set +e
  out=$(timeout 60s opencode run --standalone --agent build --model "$model"     "Do not use tools. Reply with exactly: PROVIDER_OK" 2>&1)
  rc=$?
  set -e

  if [[ $rc -eq 0 ]] && grep -q "PROVIDER_OK" <<<"$out"; then
    pass "$label"
  else
    echo "$out" | tail -n 30
    fail "$label"
  fi
}

{
  echo "## Free provider smoke test"
  echo
  echo "| Provider | Result |"
  echo "|---|---|"
} >> "$SUMMARY"

echo "OpenCode:"
opencode --version
opencode debug config >/tmp/opencode-config.txt
pass "OpenCode config parse"

echo "Kilo:"
kilo --version
kilo models >/tmp/kilo-models.txt 2>&1 || true
pass "Kilo CLI install"

if [[ "${GEMINI_FREE_ONLY:-false}" == "true" && -n "${GEMINI_API_KEY:-}" ]]; then
  TESTED=$((TESTED + 1))
  set +e
  gemini_out=$(curl -fsS --max-time 90 \
    https://generativelanguage.googleapis.com/v1beta/openai/chat/completions \
    -H "Authorization: Bearer $GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"gemini-3.8-flash","messages":[{"role":"user","content":"Reply exactly GEMINI_DIRECT_OK"}],"max_tokens":32}' 2>&1)
  gemini_rc=$?
  set -e
  if [[ $gemini_rc -eq 0 ]] && grep -q "GEMINI_DIRECT_OK" <<<"$gemini_out"; then
    pass "Gemini 3.8 Flash direct API"
  else
    echo "$gemini_out" | tail -n 20
    fail "Gemini 3.8 Flash direct API"
  fi

  run_model "Gemini 3.8 Flash via OpenCode native Google" "gemini-free/gemini-3.8-flash"
else
  skip "Gemini 3.8 Flash Free Tier" "set GEMINI_FREE_ONLY=true only for a confirmed free-only AI Studio project"
fi

if [[ -n "${KILO_API_KEY:-}" ]]; then
  run_model "Kilo Auto Free via OpenCode" "kilo-free/auto-free"

  TESTED=$((TESTED + 1))
  set +e
  kilo_cli_out=$(KILO_PROVIDER=kilo KILO_API_KEY="$KILO_API_KEY" \
    timeout 4m kilo run --auto --model "kilo/kilo-auto/free" \
    "Do not use tools. Reply exactly KILO_CLI_OK" 2>&1)
  kilo_cli_rc=$?
  set -e
  if [[ $kilo_cli_rc -eq 0 ]] && grep -q "KILO_CLI_OK" <<<"$kilo_cli_out"; then
    pass "Kilo CLI Auto Free"
  else
    echo "$kilo_cli_out" | tail -n 30
    fail "Kilo CLI Auto Free"
  fi

  TESTED=$((TESTED + 1))
  kilo_body="${RUNNER_TEMP:-/tmp}/kilo-gateway-body.json"
  set +e
  kilo_http=$(curl -sS --max-time 90 -o "$kilo_body" -w '%{http_code}' \
    https://api.kilo.ai/api/gateway/chat/completions \
    -H "Authorization: Bearer $KILO_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"kilo-auto/free","messages":[{"role":"user","content":"Reply exactly KILO_GATEWAY_OK"}],"max_tokens":32}')
  kilo_rc=$?
  set -e
  if [[ $kilo_rc -eq 0 && "$kilo_http" == "200" ]] && grep -q "KILO_GATEWAY_OK" "$kilo_body"; then
    pass "Kilo Gateway Auto Free"
  elif [[ "$kilo_http" == "429" ]]; then
    skip "Kilo Gateway Auto Free" "rate limited (HTTP 429); other Kilo paths are tested separately"
  else
    cat "$kilo_body" 2>/dev/null | tail -n 20 || true
    echo "HTTP $kilo_http"
    fail "Kilo Gateway Auto Free"
  fi
else
  skip "Kilo Auto Free" "KILO_API_KEY missing"
fi

if [[ -n "${NVIDIA_API_KEY:-}" ]]; then
  run_model "NVIDIA NIM Nemotron 3 Super" "nvidia-free/nemotron-3-super"
else
  skip "NVIDIA NIM Nemotron 3 Super" "NVIDIA_API_KEY missing"
fi

if [[ -n "${GROQ_API_KEY:-}" ]]; then
  run_model "Groq GPT-OSS 120B Free Tier" "groq-free/gpt-oss-120b"
else
  skip "Groq GPT-OSS 120B Free Tier" "GROQ_API_KEY missing"
fi

if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  run_model "OpenRouter Free Router" "openrouter-free/free"
else
  skip "OpenRouter Free Router" "OPENROUTER_API_KEY missing"
fi


# Keyless / hard-free paths. These are exercised even when no repository secret exists.
run_model "Kilo Auto Free anonymous" "kilo-anon/auto-free"
run_model "LLM7 anonymous default" "llm7-anon/default"
run_model "OVHcloud anonymous Qwen3 Coder" "ovh-anon/qwen3-coder"
run_model "uncloseai keyless Qwen3.8 27B" "uncloseai-anon/qwen3.8-27b"
run_model "Pollinations legacy keyless" "pollinations-anon/openai-fast"

if [[ -n "${HETZNER_VLLM_API_KEY:-}" ]]; then
  run_model "Hetzner Experiments Qwen3.6" "hetzner-free/qwen3.6"
else
  skip "Hetzner Experiments Qwen3.6" "HETZNER_VLLM_API_KEY missing"
fi

if [[ -n "${AION_API_KEY:-}" ]]; then
  run_model "Aion Labs Free Tier" "aion-free/aion-3-mini"
else
  skip "Aion Labs Free Tier" "AION_API_KEY missing"
fi

if [[ -n "${COHERE_API_KEY:-}" ]]; then
  run_model "Cohere North Mini Code trial" "cohere-free/north-mini-code"
else
  skip "Cohere North Mini Code trial" "COHERE_API_KEY missing"
fi

if [[ -n "${INCEPTION_API_KEY:-}" ]]; then
  run_model "Inception Mercury free allocation" "inception-free/mercury-2"
else
  skip "Inception Mercury free allocation" "INCEPTION_API_KEY missing"
fi

# These providers can have paid account modes. They are never part of the default fallback.
# Test them only when the repository owner explicitly sets the FREE_ONLY guard variable.
if [[ "${CLOUDFLARE_FREE_ONLY:-false}" == "true" && -n "${CLOUDFLARE_API_TOKEN:-}" && -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
  run_model "Cloudflare Workers AI Free guarded" "cloudflare-free/nemotron"
else
  skip "Cloudflare Workers AI Free guarded" "set CLOUDFLARE_FREE_ONLY=true plus token/account id"
fi

if [[ "${MISTRAL_FREE_ONLY:-false}" == "true" && -n "${MISTRAL_API_KEY:-}" ]]; then
  run_model "Mistral Free Mode guarded" "mistral-free/medium"
else
  skip "Mistral Free Mode guarded" "set MISTRAL_FREE_ONLY=true plus MISTRAL_API_KEY"
fi

if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  model="${AI_OLLAMA_MODEL:-qwen3-coder:30b}"
  run_model "Ollama local ($model)" "ollama/$model"
else
  skip "Ollama local" "no Ollama server on this runner"
fi

echo
echo "Configured inference tests executed: $TESTED; failures: $FAILURES"

if [[ "$STRICT" == "true" && $FAILURES -gt 0 ]]; then
  exit 1
fi
