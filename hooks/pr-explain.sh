#!/usr/bin/env bash
# PreToolUse hook for the Bash tool. Denies `gh pr create` when the pull request
# description lacks a before and after section, a table that compares the two
# states, a picture of the change, a section that explains how it works, a
# cautions section, or a not verified section.
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

# A heading starts a line, or opens an inline body right after its quote.
line=$'(^|\n|["\'])'
sides="${line}#{2,3}[[:space:]]+(Before and after|변경 전후)"
heading="${line}#{2,3}[[:space:]]+(How it works|동작 원리)"
cautions="${line}#{2,3}[[:space:]]+(Cautions|주의할 점)"
unverified="${line}#{2,3}[[:space:]]+(Not verified|확인하지 못한 것)"
# A table row whose neighboring cells name the two states.
table=$'\\|[^|\n]*([Bb]efore|변경 전)[^|\n]*\\|[^|\n]*([Aa]fter|변경 후)[^|\n]*\\|'
# What can show a change: an image in the description, a video in it, or a file
# uploaded with --attach. A mermaid block is none of these.
image='!\[[^]]*\]\(|<img[[:space:]]'
video='<video[[:space:]]|https://github\.com/user-attachments/assets/'
attach='[[:space:]]--attach[[:space:]=]+[^[:space:]]'

# Succeeds when the description shows the change before and after.
shows_change() {
  [[ "$text" =~ $image || "$text" =~ $video || "$cmd" =~ $attach ]]
}

missing=()
[[ "$text" =~ $sides ]] ||
  missing+=("a '## Before and after' section")
[[ "$text" =~ $table ]] ||
  missing+=("a table with a before column and an after column")
shows_change ||
  missing+=("a picture of the change: a recording or screenshots for a UI change, otherwise a drawn before and after image, passed with --attach")
[[ "$text" =~ $heading ]] ||
  missing+=("a '## How it works' section that explains the principle")
[[ "$text" =~ $cautions ]] ||
  missing+=("a '## Cautions' section on what the user has to watch for")
[[ "$text" =~ $unverified ]] ||
  missing+=("a '## Not verified' section")

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
