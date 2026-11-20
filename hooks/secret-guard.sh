#!/usr/bin/env bash
# UserPromptSubmit and PreToolUse hook. Blocks a prompt, shell command, or file
# write that carries a credential-shaped string, and names the kind without
# repeating the value. Anything else passes through. A blocked prompt is not
# sent to the model, but it can remain in local history; rotate the credential.
set -euo pipefail

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input" 2>/dev/null) || event=""
case "$event" in
  UserPromptSubmit) filter='.prompt' ;;
  PreToolUse) filter='.tool_input | .command, .content, .new_string, .edits[]?.new_string' ;;
  *) filter='empty' ;;
esac
text=$(jq -r "[$filter] | map(strings) | join(\"\n\")" <<<"$input" 2>/dev/null) || text=""

names=('GitHub token' 'AWS access key ID' 'Slack token' 'Slack webhook URL'
  'Discord webhook URL' 'API secret key' 'private key')
patterns=(
  '(gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40})'
  '(^|[^A-Za-z0-9])AKIA[0-9A-Z]{16}'
  'xox[abprs]-[A-Za-z0-9-]{20}'
  'hooks\.slack\.com/services/T[A-Za-z0-9]+/B[A-Za-z0-9]+/[A-Za-z0-9]{16}'
  'discord(app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]{20}'
  '(^|[^A-Za-z0-9_-])(sk-(ant|proj)-[A-Za-z0-9_-]{20}|[sr]k_live_[A-Za-z0-9]{20})'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)

found=""
if [[ -n "$text" && "${SECRET_GUARD:-1}" != 0 ]]; then
  for i in "${!patterns[@]}"; do
    if [[ "$text" =~ ${patterns[$i]} ]]; then
      found=${names[$i]}
      break
    fi
  done
fi

if [[ -z "$found" ]]; then
  echo '{}'
  exit 0
fi

reason="secret-guard: this contains a ${found}. Refer to it by environment variable or secret store name instead, and rotate it if it was real."
if [[ "$event" == UserPromptSubmit ]]; then
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason,
    hookSpecificOutput: {hookEventName: "UserPromptSubmit", suppressOriginalPrompt: true}}'
else
  jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $reason}}'
fi
