---
name: dolpa
description: Take one work item, such as a spec task, an issue, or a plain request, from spec to a merged pull request on a minimal token budget, with deterministic gates first, one independent review per green head, and the user asked only for critical decisions. Invoke with /dolpa. Do not use for explanations, reviews of someone else's PR, or single edits.
disable-model-invocation: true
---

# Dolpa

Run one work item through a fixed line. Repository instructions and the user's standing approvals outrank this skill; where they are silent, this skill decides. Without a standing merge approval for the repository, stop at a reviewed, green pull request.

A work item is whatever the repository already tracks: a task in a spec, an issue, or a request made in the conversation. Do not create issues, labels, or tracking files in a repository that does not use them.

## Line

| State | Work | Exit |
|---|---|---|
| Intake | Check the item for acceptance criteria and scope, with a template or script where one exists. | Checkable acceptance criteria and a list of what is out of scope |
| Spec | Write the requirement, design note, tasks, and failing acceptance tests. | Item ready to implement |
| Implement | One task, one fresh session, one branch. | Required local checks pass, PR opened |
| Verify | CI only. No model. | Every required check is green on the head |
| Review | One isolated reviewer reads the diff, as Review below sets out. | No blocking finding on the current head |
| Merge | Merge, delete the branch and its worktree, then check the deployed change. | Check recorded, item marked done |

Record the state where the item lives, so any session can resume it without earlier conversation: the task's status in the spec's task list, labels on an issue (`ready-to-spec`, `ready-to-implement`, `needs-info`, `needs-human`), or the pull request description for a plain request. Scale each state to the item, and skip one that has nothing to do with one line saying why. An item that cannot advance is marked `needs-human` there with the blocker named; continue with other items.

When an item is split across stacked pull requests, the parent item lists each slice in one line with its state, built with `gh pr list` and no model. The user follows that list, not each slice.

## Start Conditions

- Ask every open question in one batch before implementing. When a request reverses a decision settled earlier in the item, confirm once before acting on it.
- Look for existing work on the item first: `gh pr list --state open --search "<item id or key words>"` and `git branch --all --list "*<item id>*"`. Resume it instead of opening a second branch.
- Keep at most two items in progress per repository unless the user set another limit. One worktree holds one item; never reuse it for a different one.
- Slice a task in the Spec state so its diff outside tests stays under about 400 changed lines, unless the repository sets another limit. A task that cannot be sliced says why in the item.
- Performance or cost work needs a measured baseline, a target, and a stop condition in the item. Test one hypothesis per pull request, and revert it when the measurement gets worse.
- When the user's own instructions set working hours or a weekly item cap, start new work only inside them. Outside them, record the request where the repository tracks work and do not implement it unless the user states why it is urgent; record that reason with it.

## Token Rules

- One work item per session. Start it fresh; do not carry another item's conversation.
- Load only the item, its spec section, and the files it names. Locate anything else by search, not by reading directories.
- Never ask a model what a compiler, linter, test, `git`, or `gh` can answer.
- Keep tool output out of context. Send check output to a file and read the summary; on failure read only the failing section.
- Do not review a red head. Classify the failure before spending a fix cycle. A failure in code the diff does not touch means a stale base, so update from the base. A flake gets one `gh run rerun <id> --failed`, never a second. Only a failure in the diff's own code is a fix cycle.
- No fan-out by default. Only when the spec leaves a decision with two or more workable options and reversing it later is expensive, read `references/design-panel.md` and run its three-vendor panel before writing the design note.
- Route by need. Raise the model or effort only after a failed attempt, and say why.

  | Work | Model | Effort |
  |---|---|---|
  | Spec, critical decision | strongest | high |
  | Implementation, review | mid-tier | medium |
  | Rename, format, conflict merge, log triage | smallest, or a subagent on it | low |

- Wait without spending turns: block once on `gh pr checks <n> --watch --fail-fast >/dev/null`, then read `gh pr checks <n>` once. Cap unattended runs, for example `claude -p --model <m> --effort <e> --max-budget-usd <n>`.
- Stop after three fix cycles on one item. Mark it `needs-human` and report the blocker; do not restart the count.

## Review

- The reviewer is a separate process or a fresh subagent working in a checkout of the head with no uncommitted changes. Never a fork or a continuation of the authoring session. One completed review per head.
- Take the first reviewer that works, in this order: another vendor's CLI, such as `codex review --base <branch>`, then `gemini -p` or `cursor-agent -p`; the author's vendor on a different model, such as `claude -p --model <other>`; the author's own model in a fresh process. A different vendor is preferred, not required. The isolation rules below hold for every one of them.
- A reviewer that exits non-zero, reports a usage limit, or returns nothing has not reviewed. Do not retry it or wait for it. Move to the next, and name in the description the reviewer that ran and why each earlier one did not. A review bot on the pull request that has not finished is not the review.
- Its whole input is the base and head commits and the acceptance criteria. Withhold the conversation, the pull request description, the author's summary, test results, and earlier findings, and tell it not to read the pull request or the commit log. Say nothing about what the change fixes or why it is safe.
- It reports only defects it can show, most severe first, ten at most: file and line, the input or state that fails, and the wrong result. An empty report is a valid result. It does not rerun checks CI ran, and opens files outside the diff only to confirm a suspected defect.
- Send its output to a file and read only the findings. Answer each with a commit, or with a command and its output showing the failure cannot occur. An opinion does not dismiss a finding. After a fix, start a new reviewer on the range since the reviewed head with the same criteria; do not resume the earlier one.
- A review covers a patch, not a commit. When the head changes without a fix, as after a rebase, the review stands only if `git diff <base>...<head> | git patch-id --stable` is unchanged and CI is green on the new head.

## Acceptance Tests

- Write them in the Spec state from the requirement, before the implementation exists, and confirm they fail.
- The implementing session does not edit, skip, or weaken them. If one is wrong, send the item back to Spec.
- Where the repository allows it, enforce this in CI: fail a pull request that changes an acceptance test path unless it carries `spec-change`.
- Every bug fix adds a regression that fails on the base and passes on the head.

## Decisions

Decide reversible questions yourself, record the choice and its reason in the pull request, and continue. Stop and ask the user, and do not merge, when the item involves any of these:

- Loss or migration of production data, or anything that cannot be undone. Change production data only through a script in the pull request, run dry first, never by an ad hoc query.
- Authentication, authorization, secrets, or a trust boundary.
- Payments or orders, spending money, deploy scripts, deploying, releasing, or publishing.
- Agent instructions, permission settings, CI gates, or check allowlists.
- A requirement that contradicts another requirement or the user's stated intent.

These are the pull requests the user reads before merge; for the rest, the command in the description is the user's check. Ask with one question that states the decision, the options, and what each option costs. If no question tool is available, mark the item `needs-human` and stop that item only.

## Evidence

- The pull request description opens with two sentences on what changed and why, and one command the user can run to see it themselves. It then lists up to three decisions made on the user's behalf, each with the alternative and the spec line to change to reverse it.
- Write the description's prose as sentence pairs: each sentence in the user's language on its own line, its English sentence on the next line, and a blank line between pairs. Keep the same sentence count and order in both, so each pair says one thing. Write the English the way a fluent speaker would say it to a colleague, not word for word, and keep one English term for each technical term. A table cell or list item holds both, the user's language first. When the user's language is English, write it once. Image labels use the user's language. Commands, output, and identifiers are not translated, and each word limit applies per language.
- Under `## Before and after` (or `## 변경 전후`), it compares one concrete case in both states: the same input or action, and what the user got before and gets now. A table of at most four rows, one per difference, has a before column and an after column that hold the observed value, not an adjective. Below it, a UI change shows the real screen in both states, as a recording when one can be made and screenshots otherwise; capture the before state before the first edit. Any other change gets one drawn image of that case in both states. Draw no `mermaid` diagram anywhere in the description. Read `references/visuals.md` before making either.
- Under `## How it works` (or `## 동작 원리`), explain the principle in at most 150 words: what the thing is in general terms, how this change uses it, the path one input takes through it, and why it is built this way and not the obvious alternative. State the mechanism, not a metaphor or a file list, and end with the two or three files to open first. Write it from what the session already loaded; start no explorer or second model for it.
- Under `## Edge cases` (or `## 엣지 케이스`), right after the before and after section, teach the cases where the change does not do what the user would expect, most severe first, five at most. Each has a bold title that states the surprise and four lines: the situation with a real value, what happens, why the mechanism does that, and what to do. Take them from inputs tried or code paths read, not from general advice, and mark one that was not run `NOT_RUN(reason)`. Open the section with one GitHub alert for the case that costs the most: `> [!CAUTION]` when it loses data or cannot be undone, `> [!WARNING]` otherwise. Under `## Not verified` (or `## 확인하지 못한 것`), list each claim that was not checked as `NOT_RUN(reason)` with the command or condition that would check it. Write `None` in a section that is empty.
- The user reads the spec change, not the code. A correction arrives as a comment on a spec line or acceptance criterion and sends the item back to Spec.
- The description carries an artifact that settles its claims: the commands run and their actual output, bound to the head commit. A summary or an agent's statement that it works is not an artifact. A change that depends on data adds the result of running it against real data.
- After the merge, check the change once where it is deployed and record the result on the item before marking it done. If it is not deployed yet, leave the item open.
- Report each check as `PASS(scope, evidence)`, `FAIL(reason)`, `NOT_RUN(reason)`, or `NOT_APPLICABLE(reason)`. Agreement among agents is not evidence.
- Update a pull request by adding commits and comments. Do not rewrite its description or history to hide an earlier state.

## Outer Loop

Read `references/outer-loop.md` when asked to improve the line itself, or after about ten merged items. Do not read it during an item.
