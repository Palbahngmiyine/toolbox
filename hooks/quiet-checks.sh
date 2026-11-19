#!/usr/bin/env bash
# PreToolUse hook for the Bash tool. Rewrites a recognized check command so its
# output goes to a log file and only the tail enters the model's context. The
# command's exit status is preserved. Anything unrecognized passes through.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || cmd=""

js='(pnpm|npm|yarn|bun)( run| exec)? (test|typecheck|lint|build|check|format:check|vitest|jest|tsc)[A-Za-z0-9:_-]*'
bare='(npx |bunx )?(vitest|jest|tsc|pytest|oxlint|eslint)'
other='cargo (test|build|check|clippy)|go (test|build|vet)|dotnet (test|build)|make (test|check|lint|build)'
args='( [^;&|<>`$#\\[:cntrl:]]*)?'
pattern="^(${js}|${bare}|${other})${args}\$"

if [[ -z "$cmd" || ! "$cmd" =~ $pattern ]]; then
  echo '{}'
  exit 0
fi

ok=${QUIET_CHECKS_OK_LINES:-5}
fail=${QUIET_CHECKS_FAIL_LINES:-80}
if [[ ! "$ok" =~ ^[0-9]+$ || ! "$fail" =~ ^[0-9]+$ ]]; then
  echo '{}'
  exit 0
fi

quiet='log=$(mktemp "${TMPDIR:-/tmp}/quiet-checks.XXXXXX"); '"$cmd"' >"$log" 2>&1; s=$?; '
quiet+='if [ "$s" -eq 0 ]; then tail -n '"$ok"' "$log"; else tail -n '"$fail"' "$log"; fi; '
quiet+='echo "[quiet-checks] exit=$s lines=$(wc -l <"$log" | tr -d " ") log=$log"; (exit "$s")'

jq --arg command "$quiet" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: (.tool_input + {command: $command})}}' \
  <<<"$input"
