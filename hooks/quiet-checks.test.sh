#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
hook="$here/quiet-checks.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

cat >"$tmp/pytest" <<'EOF'
#!/usr/bin/env bash
for i in $(seq 1 200); do echo "line $i"; done
echo "to stderr" >&2
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "$tmp/pytest"

check() {
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected [$3], got [$2]"
    failures=$((failures + 1))
  fi
}

payload() { jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c, timeout: 5000}}'; }
rewritten() { payload "$1" | "$hook" | jq -r '.hookSpecificOutput.updatedInput.command // empty'; }
run() { PATH="$tmp:$PATH" TMPDIR="$tmp" FAKE_EXIT="$1" bash -c "$2"; }

for passthrough in 'ls -la' 'pytest; rm -rf x' 'pytest | tee out' 'pytest $(id)' 'QUIET_CHECKS=0 pytest' 'git status' 'pytestx'; do
  check "passes through: $passthrough" "$(payload "$passthrough" | "$hook")" '{}'
done
check 'passes through malformed input' "$(echo 'not json' | "$hook")" '{}'
check 'passes through missing command' "$(echo '{"tool_input":{}}' | "$hook")" '{}'
check 'passes through bad line setting' "$(payload 'pytest' | QUIET_CHECKS_OK_LINES=x "$hook")" '{}'

for recognized in 'pytest' 'pytest -k "a b" tests/' 'pnpm test' 'pnpm test:backend --run' 'npm run lint' 'npx vitest run' 'cargo test --workspace' 'go test ./...' 'dotnet test' 'make check'; do
  [[ -n "$(rewritten "$recognized")" ]] && got=rewritten || got=untouched
  check "rewrites: $recognized" "$got" rewritten
done

check 'keeps other tool input fields' \
  "$(payload 'pytest' | "$hook" | jq -r '.hookSpecificOutput.updatedInput.timeout')" 5000

cmd=$(rewritten 'pytest -q')
set +e
out=$(run 0 "$cmd"); status=$?
set -e
check 'success keeps exit status 0' "$status" 0
check 'success prints 5 lines and a summary' "$(wc -l <<<"$out" | tr -d ' ')" 6
check 'success captures stderr in the log' "$(grep -c 'to stderr' <<<"$out")" 1
check 'summary reports the full line count' "$(grep -c 'exit=0 lines=201 log=' <<<"$out")" 1

set +e
out=$(run 3 "$cmd"); status=$?
set -e
check 'failure keeps exit status 3' "$status" 3
check 'failure prints 80 lines and a summary' "$(wc -l <<<"$out" | tr -d ' ')" 81

log=$(sed -n 's/.* log=//p' <<<"$out")
check 'full log is kept for inspection' "$(wc -l <"$log" | tr -d ' ')" 201

cmd=$(payload 'pytest' | QUIET_CHECKS_FAIL_LINES=10 "$hook" | jq -r '.hookSpecificOutput.updatedInput.command')
set +e
out=$(run 1 "$cmd")
set -e
check 'line count is configurable' "$(wc -l <<<"$out" | tr -d ' ')" 11

if [[ "$failures" -gt 0 ]]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
