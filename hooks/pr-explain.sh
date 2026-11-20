#!/usr/bin/env bash
# PreToolUse hook for the Bash tool. Denies `gh pr create` when the pull request
# description lacks a visual or a section that explains how the change works.
# It reads the description from the command or from its body file. Anything
# else passes through.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || cmd=""
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null) || cwd=""

# `gh` must stand where a command starts: at the beginning, or after a separator,
# with optional NAME=value assignments before it. The words inside a commit
# message or an echo are not a command.
start='(^|[;&|('$'\n''])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
create="${start}gh[[:space:]]+pr[[:space:]]+create([[:space:]]|\$)"
web='[[:space:]](--web|-w)([[:space:]]|$)'
# --help and --dry-run create nothing. They pass only when the command carries
# no description, so a description that mentions them is still checked.
info='[[:space:]](--help|-h|--dry-run)([[:space:]]|$)'
body='[[:space:]](--body|-b|--body-file|-F|--fill[a-z-]*|--template|-T)([[:space:]=]|$)'
if [[ "${PR_EXPLAIN:-1}" == 0 || ! "$cmd" =~ $create || "$cmd" =~ $web ]] ||
  [[ "$cmd" =~ $info && ! "$cmd" =~ $body ]]; then
  echo '{}'
  exit 0
fi

text=$cmd
file='[[:space:]](--body-file|-F)[[:space:]=]+("[^"]+"|'"'[^']+'"'|[^[:space:]]+)'
if [[ "$cmd" =~ $file ]]; then
  path=${BASH_REMATCH[2]}
  path=${path#[\"\']}
  path=${path%[\"\']}
  [[ "$path" == /* || -z "$cwd" ]] || path="$cwd/$path"
  if [[ ! -f "$path" || ! -r "$path" ]]; then
    echo '{}'
    exit 0
  fi
  text=$(cat "$path")
fi

visual='```mermaid|!\[[^]]*\]\(|<img[[:space:]]'
heading=$'(^|\n)#{2,3}[[:space:]]+(How it works|동작 원리)'
missing=()
[[ "$text" =~ $visual ]] ||
  missing+=("a visual: screenshots for a UI change, otherwise a mermaid diagram of the mechanism")
[[ "$text" =~ $heading ]] ||
  missing+=("a '## How it works' section that explains the principle")

if [[ ${#missing[@]} -eq 0 ]]; then
  echo '{}'
  exit 0
fi

reason="pr-explain: the pull request description is missing"
for i in "${!missing[@]}"; do
  [[ "$i" -eq 0 ]] || reason+=" and"
  reason+=" ${missing[$i]}"
done
reason+=". Write the description to a file and pass it with --body-file."
jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse",
  permissionDecision: "deny", permissionDecisionReason: $reason}}'
