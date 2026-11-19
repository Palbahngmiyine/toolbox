# Instructions

## Read First

- Respond in Korean. Keep identifiers and instruction text in English.
- This repository is public. It holds reusable agent tooling: skills under `skills/` and hooks under `hooks/`. Never add private repository names, local paths, session content, credentials, or personal data.
- Read the file you change and every file that refers to it before editing. Preserve user-owned changes and unrelated files.
- Explanation, review, and planning requests get no edits. A PR request covers the branch, commits, and PR, not merging.

## Token Budget

Every line in this repository is paid for again in each session that loads it. Treat tokens as the scarce resource.

- Prefer a deterministic tool over an instruction, and an instruction over a model call. When a script, hook, linter, or CI check can enforce a rule, write that and delete the prose.
- A skill `description` loads in every session. Keep it to what the skill does, when to use it, and when not to.
- A skill body loads on every use. Keep a new or edited `SKILL.md` at 100 lines or fewer, and write only what a capable model would otherwise get wrong. Do not restate general knowledge, tool manuals, or examples the model can produce itself.
- Put rarely needed detail in `references/` and state the condition for reading each file.
- Do not add a skill for what one sentence in a prompt achieves. Delete a skill that is no longer used.
- Leave existing files over the limit alone until they are edited for another reason.

## Skills

- A skill lives at `skills/<name>/SKILL.md` with `name` and `description` frontmatter. `name` matches the directory.
- A skill is Markdown guidance. Do not hide a runner, script, or machine-read contract inside it; executable behavior belongs in `hooks/` with a test.
- State what stops the skill and what needs the user.
- Repository instructions outrank a skill. Say so in any skill that touches Git, review, or merge.

## Hooks

- Write hooks in Bash with `set -euo pipefail`, depending only on `bash` 3.2 and `jq`.
- A hook passes through whatever it does not recognize: print `{}` and exit 0. It never changes a command's exit status or meaning.
- Each hook has `<name>.test.sh` beside it. A test names the behavior it checks and fails when that behavior is removed.

## Verification

- Skill change: confirm the frontmatter, the line count, and that every path and command it names exists.
- Hook change: run its test with `bash hooks/<name>.test.sh`.
- Every change: `git diff --check`.
- Report each result as `PASS(scope, evidence)`, `FAIL(reason)`, `NOT_RUN(reason)`, or `NOT_APPLICABLE(reason)`. Never delete or weaken a test to get a pass.
- Do not add per-run review files or work logs.

## Pull Requests

- Use Conventional Commits and keep one purpose per pull request.
- The description includes the commands run and their actual output.
