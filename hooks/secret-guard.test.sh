#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
hook="$here/secret-guard.sh"
failures=0

check() {
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected [$3], got [$2]"
    failures=$((failures + 1))
  fi
}

# Fixtures are assembled at run time so this file holds no credential-shaped text.
rep() { printf "%${2}s" '' | tr ' ' "$1"; }
gh_token="gh""p_$(rep a 36)"
samples=(
  "GitHub token|$gh_token"
  "GitHub token|github""_pat_$(rep b 40)"
  "AWS access key ID|AKIA""$(rep A 16)"
  "Slack token|xox""b-$(rep 1 20)"
  "Slack webhook URL|https://hooks.slack.com/services/T000/B000/""$(rep c 24)"
  "Discord webhook URL|https://discord.com/api/webhooks/123/""$(rep d 30)"
  "API secret key|sk-ant""-$(rep e 30)"
  "API secret key|sk_live""_$(rep f 24)"
  "private key|-----BEGIN RSA PRIVATE"" KEY-----"
)

prompt() { jq -n --arg p "$1" '{hook_event_name: "UserPromptSubmit", prompt: $p}'; }
tool() { jq -n --arg n "$1" --argjson i "$2" '{hook_event_name: "PreToolUse", tool_name: $n, tool_input: $i}'; }
field() { jq -n --arg k "$1" --arg v "$2" '{($k): $v}'; }
denied() { "$hook" | jq -r '.hookSpecificOutput.permissionDecision // "passed"'; }

for sample in "${samples[@]}"; do
  kind=${sample%%|*}
  out=$(prompt "post this: ${sample#*|} please" | "$hook")
  check "blocks a prompt with a $kind" "$(jq -r '.decision // "passed"' <<<"$out")" block
  check "names the $kind" "$(jq -r '.reason' <<<"$out" | grep -c "contains a $kind\.")" 1
done

out=$(prompt "use $gh_token" | "$hook")
check 'reason does not repeat the value' "$(grep -c "$gh_token" <<<"$out" || true)" 0
check 'block message leaves out the prompt' \
  "$(jq -r '.hookSpecificOutput.suppressOriginalPrompt' <<<"$out")" true

check 'denies a shell command' "$(tool Bash "$(field command "curl -H 'Authorization: $gh_token' x")" | denied)" deny
check 'denies a file write' "$(tool Write "$(field content "TOKEN=$gh_token")" | denied)" deny
check 'denies an edit that adds one' "$(tool Edit "$(field new_string "$gh_token")" | denied)" deny
check 'denies a multi-edit that adds one' \
  "$(tool MultiEdit "$(jq -n --arg v "$gh_token" '{edits: [{new_string: "ok"}, {new_string: $v}]}')" | denied)" deny
check 'deny reason reaches the agent' \
  "$(tool Bash "$(field command "echo $gh_token")" | "$hook" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -c 'environment variable')" 1

check 'passes an edit that removes one' "$(tool Edit "$(field old_string "$gh_token")" | "$hook")" '{}'
check 'passes a tool input field it does not scan' "$(tool Read "$(field file_path "$gh_token")" | "$hook")" '{}'
check 'passes an event it does not handle' \
  "$(jq -n --arg p "$gh_token" '{hook_event_name: "PostToolUse", prompt: $p}' | "$hook")" '{}'
check 'passes when switched off' "$(prompt "$gh_token" | SECRET_GUARD=0 "$hook")" '{}'
check 'passes malformed input' "$(echo 'not json' | "$hook")" '{}'
for clean in 'fix the login bug' "gh""p_$(rep a 10)" "risk-ant""-$(rep e 30)" "task-proj""-$(rep e 30)" \
  'read the key from $GITHUB_TOKEN' 'https://hooks.slack.com/services/ is the prefix'; do
  check "passes a prompt: ${clean:0:24}" "$(prompt "$clean" | "$hook")" '{}'
done
check 'passes an ordinary command' "$(tool Bash "$(field command 'git status')" | "$hook")" '{}'

if [[ "$failures" -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
