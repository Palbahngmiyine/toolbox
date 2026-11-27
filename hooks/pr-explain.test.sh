#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
hook="$here/pr-explain.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

check() {
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected [$3], got [$2]"
    failures=$((failures + 1))
  fi
}

payload() { jq -n --arg c "$1" --arg d "$tmp" '{tool_name: "Bash", cwd: $d, tool_input: {command: $c}}'; }
verdict() { payload "$1" | "$hook" | jq -r '.hookSpecificOutput.permissionDecision // "passed"'; }
reason() { payload "$1" | "$hook" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""'; }

fence='```'
diagram="${fence}mermaid"$'\nflowchart LR\n  a --> b\n'"${fence}"
rows=$'| | Before | After |\n|---|---|---|\n| result | blocked | passes |'
sides=$'## Before and after\n\n'"$rows"$'\n\n![Before and after](./before-after.png)'
how=$'## How it works\n\nA request passes the guard, then the store.'
cautions=$'## Cautions\n\n- Restart the agent after the merge, or the old guard keeps running.'
unverified=$'## Not verified\n\nNone'
notes="$cautions"$'\n\n'"$unverified"
printf '%s\n\n%s\n\n%s\n' "$sides" "$how" "$notes" >"$tmp/full.md"
printf '%s\n\n%s\n' \
  $'## 변경 전후\n\n| 항목<br>Item | 변경 전<br>Before | 변경 후<br>After |\n|---|---|---|\n| 화면 | ![전](before.png) | ![후](after.png) |' \
  $'## 동작 원리\n\n요청은 검사를 거쳐 저장소로 갑니다.\n\n## 주의할 점\n\n없음\n\n## 확인하지 못한 것\n\n없음' >"$tmp/korean.md"
printf '%s\n\n%s\n\n%s\n\n%s\n' $'## Before and after\n\nThe recordings follow, before first.' "$rows" "$how" "$notes" >"$tmp/recording.md"
printf '%s\n\n%s\n\n%s\n\n%s\n' $'## Before and after\n\nhttps://github.com/user-attachments/assets/0a1b2c' "$rows" "$how" "$notes" >"$tmp/video.md"
printf '%s\n\n%s\n\n%s\n\n%s\n\n%s\n' $'## Before and after\n\nSee the diagram.' "$rows" "$diagram" "$how" "$notes" >"$tmp/mermaid-only.md"
printf '%s\n\n%s\n\n%s\n\n%s\n' $'## Before and after\n\nPass the image with --attach later.' "$rows" "$how" "$notes" >"$tmp/mention.md"
printf '%s\n\n%s\n\n%s\n' $'## Before and after\n\n![Before and after](./before-after.png)' "$how" "$notes" >"$tmp/no-table.md"
printf '%s\n\n%s\n\n%s\n' $'## Before and after\n\n| | After |\n|---|---|\n| result | passes |\n\n![after](./after.png)' "$how" "$notes" >"$tmp/after-only.md"
printf '%s\n\n%s\n\n%s\n' $'## Before and after\n\n| | Before |\n|---|---|\n| result | blocked |\n\n![before](./before.png)' "$how" "$notes" >"$tmp/before-only.md"
printf '%s\n\n%s\n\n%s\n\n%s\n' "$rows" '![after](after.png)' "$how" "$notes" >"$tmp/no-sides.md"
printf '%s\n\n%s\n' "$sides" "$notes" >"$tmp/no-heading.md"
printf '%s\n\n%s\n\n%s\n' "$sides" "$how" "$unverified" >"$tmp/no-cautions.md"
printf '%s\n\n%s\n\n%s\n' "$sides" "$how" "$cautions" >"$tmp/no-unverified.md"
printf '%s\n' 'Fixes the bug.' >"$tmp/bare.md"
cp "$tmp/full.md" "$tmp/with space.md"

for passthrough in 'git status' 'gh pr list' 'gh pr view 3' 'echo gh pr created' 'gh pr create --web' \
  'gh pr create --body-file missing.md' 'gh pr create -F -' 'gh pr edit 3 --body x' \
  'gh pr create --help' 'gh pr create -h' 'gh pr create --dry-run' 'echo gh pr create --fill' \
  'git commit -m "use gh pr create here"' 'grep -n "gh pr create" README.md'; do
  check "passes through: $passthrough" "$(payload "$passthrough" | "$hook")" '{}'
done
check 'passes through malformed input' "$(echo 'not json' | "$hook")" '{}'
check 'passes through when switched off' "$(payload 'gh pr create --fill' | PR_EXPLAIN=0 "$hook")" '{}'

check 'allows a body file with the table, the picture, and every section' "$(verdict 'gh pr create --body-file full.md')" passed
check 'allows Korean headings and a table with two-language cells' "$(verdict 'gh pr create -F korean.md')" passed
check 'allows recordings passed with --attach' \
  "$(verdict 'gh pr create -F recording.md --attach before.mp4 --attach after.mp4')" passed
check 'allows an uploaded video address in the body' "$(verdict 'gh pr create -F video.md')" passed
check 'allows --body-file=path' "$(verdict 'gh pr create --title t --body-file=full.md')" passed
check 'allows a quoted path with a space' "$(verdict 'gh pr create --body-file "with space.md"')" passed
check 'allows an absolute path' "$(verdict "gh pr create --body-file $tmp/full.md")" passed
check 'allows an inline body that opens with a heading' "$(verdict "gh pr create --body \"$(cat "$tmp/full.md")\"")" passed
check 'allows a create after another command' "$(verdict 'git push -u origin x && gh pr create -F full.md')" passed

check 'denies a body with nothing' "$(verdict 'gh pr create --body-file bare.md')" deny
check 'denies --fill' "$(verdict 'gh pr create --fill')" deny
check 'denies a mermaid block as the only picture' "$(verdict 'gh pr create --body-file mermaid-only.md')" deny
check 'denies recordings that are not attached' "$(verdict 'gh pr create -F recording.md')" deny
check 'denies a body file that only mentions --attach' "$(verdict 'gh pr create -F mention.md')" deny
check 'denies a body without the comparison table' "$(verdict 'gh pr create --body-file no-table.md')" deny
check 'denies a table with only an after column' "$(verdict 'gh pr create --body-file after-only.md')" deny
check 'denies a table with only a before column' "$(verdict 'gh pr create --body-file before-only.md')" deny
check 'denies a body without the before and after section' "$(verdict 'gh pr create --body-file no-sides.md')" deny
check 'denies a body without the how it works section' "$(verdict 'gh pr create --body-file no-heading.md')" deny
check 'denies a body without the cautions section' "$(verdict 'gh pr create --body-file no-cautions.md')" deny
check 'denies a body without the not verified section' "$(verdict 'gh pr create --body-file no-unverified.md')" deny
check 'denies a create after an assignment' "$(verdict 'GH_REPO=o/r gh pr create --fill')" deny
check 'denies a create on a later line' "$(verdict $'git push\ngh pr create --fill')" deny
check 'denies a create in a subshell' "$(verdict '(gh pr create --fill)')" deny
check 'denies --dry-run that carries a description' "$(verdict 'gh pr create --dry-run --body-file bare.md')" deny
check 'denies a description that only mentions --help' "$(verdict 'gh pr create --body "see --help for flags"')" deny
check 'denies a heading that is not at a line start' \
  "$(verdict "gh pr create --body \"${sides} see ## How it works\"")" deny

check 'names only the missing picture' \
  "$(reason 'gh pr create --body-file mermaid-only.md' | grep -c 'is missing a picture of the change.*--attach\. Write')" 1
check 'names only the missing table' \
  "$(reason 'gh pr create --body-file no-table.md' | grep -c 'is missing a table with a before column and an after column\. Write')" 1
check 'names only the missing before and after section' \
  "$(reason 'gh pr create --body-file no-sides.md' | grep -c "is missing a '## Before and after' section\. Write")" 1
check 'names only the missing how it works section' \
  "$(reason 'gh pr create --body-file no-heading.md' | grep -c "is missing a '## How it works' section")" 1
check 'names only the missing cautions section' \
  "$(reason 'gh pr create --body-file no-cautions.md' | grep -c "is missing a '## Cautions' section on what the user has to watch for\. Write")" 1
check 'names only the missing not verified section' \
  "$(reason 'gh pr create --body-file no-unverified.md' | grep -c "is missing a '## Not verified' section\. Write")" 1
check 'names all six when all are missing' \
  "$(reason 'gh pr create --body-file bare.md' |
    grep -c 'Before and after.* and a table.* and a picture.* and a .## How it works.* and a .## Cautions.* and a .## Not verified')" 1

if [[ "$failures" -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
