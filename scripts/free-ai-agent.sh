#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

START_SHA="$(git rev-parse HEAD)"
LOG="${RUNNER_TEMP:-/tmp}/free-ai-agent.log"
PROVIDER_FILE="${RUNNER_TEMP:-/tmp}/free-ai-provider.txt"

: > "$LOG"
rm -f "$PROVIDER_FILE"

MODE="${AI_MODE:-implement}"
TASK="${AI_TASK:-Inspect the repository and make the smallest safe change.}"
ORDER="${AI_PROVIDER_ORDER:-kilo,kiloanon,nvidia,openrouter,ovh,llm7,pollinations,ollama}"
OLLAMA_MODEL="${AI_OLLAMA_MODEL:-qwen3-coder:30b}"

PROMPT=$(cat <<EOF
You are running as an autonomous coding agent inside a trusted CI checkout.

Mode: $MODE
Task:
$TASK

Follow AGENTS.md exactly. Work only in this repository. Do not inspect or expose secrets or environment variables.
Do not commit or push. The outer workflow handles Git.
If mode is review, do not modify files.
When implementing or fixing, make the smallest coherent change and run the most relevant tests.
Finish with a concise summary and test results.
EOF
)

restore_repo() {
  git reset --hard "$START_SHA" >/dev/null 2>&1 || true
  git clean -fd >/dev/null 2>&1 || true
}

record_success() {
  printf '%s
' "$1" > "$PROVIDER_FILE"
}

run_opencode() {
  local label="$1"
  local model="$2"

  echo "=== Trying $label ($model) ===" | tee -a "$LOG"
  restore_repo

  set +e
  timeout 25m opencode run     --standalone     --agent build     --model "$model"     "$PROMPT" 2>&1 | tee -a "$LOG"
  rc=${PIPESTATUS[0]}
  set -e

  if [[ $rc -eq 0 ]]; then
    record_success "$label"
    return 0
  fi

  echo "$label failed with exit code $rc" | tee -a "$LOG"
  restore_repo
  return 1
}

for raw in ${ORDER//,/ }; do
  provider="${raw//[[:space:]]/}"
  case "$provider" in
    gemini)
      [[ -n "${GEMINI_API_KEY:-}" ]] && run_opencode "gemini-3.8-flash-free" "gemini-free/gemini-3.8-flash" && exit 0
      ;;
    kilo)
      [[ -n "${KILO_API_KEY:-}" ]] && run_opencode "kilo-auto-free" "kilo-free/auto-free" && exit 0
      ;;
    nvidia)
      [[ -n "${NVIDIA_API_KEY:-}" ]] && run_opencode "nvidia-nim-free" "nvidia-free/nemotron-3-super" && exit 0
      ;;
    groq)
      [[ -n "${GROQ_API_KEY:-}" ]] && run_opencode "groq-free" "groq-free/gpt-oss-120b" && exit 0
      ;;
    openrouter)
      [[ -n "${OPENROUTER_API_KEY:-}" ]] && run_opencode "openrouter-free-router" "openrouter-free/free" && exit 0
      ;;
    kiloanon)
      run_opencode "kilo-auto-free-anonymous" "kilo-anon/auto-free" && exit 0
      ;;
    llm7)
      run_opencode "llm7-anonymous-codestral" "llm7-anon/default" && exit 0
      ;;
    ovh)
      run_opencode "ovh-anonymous-qwen3-coder" "ovh-anon/qwen3-coder" && exit 0
      ;;
    pollinations)
      run_opencode "pollinations-legacy-keyless" "pollinations-anon/openai-fast" && exit 0
      ;;
    ollama)
      if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        run_opencode "ollama-local" "ollama/$OLLAMA_MODEL" && exit 0
      fi
      ;;
    "")
      ;;
    *)
      echo "Unknown provider in AI_PROVIDER_ORDER: $provider" | tee -a "$LOG"
      ;;
  esac
done

restore_repo
echo "No configured provider completed the task." | tee -a "$LOG"
echo "Add at least one provider secret, or use a self-hosted runner with Ollama." | tee -a "$LOG"
exit 1
