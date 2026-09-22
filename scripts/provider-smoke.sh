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
  out=$(timeout 4m opencode run --standalone --agent build --model "$model"     "Do not use tools. Reply with exactly: PROVIDER_OK" 2>&1)
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

if [[ -n "${GEMINI_API_KEY:-}" ]]; then
  run_model "Gemini 3.8 Flash Free Tier" "gemini-free/gemini-3.8-flash"
else
  skip "Gemini 3.8 Flash Free Tier" "GEMINI_API_KEY missing"
fi

if [[ -n "${KILO_API_KEY:-}" ]]; then
  run_model "Kilo Auto Free via OpenCode" "kilo-free/auto-free"

  TESTED=$((TESTED + 1))
  set +e
  kilo_out=$(curl -fsS --max-time 90     https://api.kilo.ai/api/gateway/chat/completions     -H "Authorization: Bearer $KILO_API_KEY"     -H "Content-Type: application/json"     -d '{"model":"kilo-auto/free","messages":[{"role":"user","content":"Reply exactly KILO_GATEWAY_OK"}],"max_tokens":32}' 2>&1)
  kilo_rc=$?
  set -e
  if [[ $kilo_rc -eq 0 ]] && grep -q "KILO_GATEWAY_OK" <<<"$kilo_out"; then
    pass "Kilo Gateway Auto Free"
  else
    echo "$kilo_out" | tail -n 20
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
