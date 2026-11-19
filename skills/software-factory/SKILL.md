---
name: software-factory
description: Take one issue or spec task from spec to a merged pull request on a minimal token budget, with deterministic gates first, one independent review per green head, and the user asked only for critical decisions. Use for "factory", "공장", "자율 병합", or issue-to-merge requests. Do not use for explanations, reviews of someone else's PR, or single edits.
---

# Software Factory

Run one work item through a fixed line. Repository instructions and the user's standing approvals outrank this skill; where they are silent, this skill decides. Without a standing merge approval for the repository, stop at a reviewed, green pull request.

## Line

Labels on the issue hold the state, so any session can resume an item without earlier conversation.

| State | Label | Work | Exit |
|---|---|---|---|
| Intake | none | No model. Check the issue against its template. | Checkable acceptance criteria, else `needs-info` |
| Spec | `ready-to-spec` | Write the requirement, design note, tasks, and failing acceptance tests. | `ready-to-implement` |
| Implement | `ready-to-implement` | One task, one fresh session, one branch. | Required local checks pass, PR opened |
| Verify | PR open | CI only. No model. | Every required check is green on the head |
| Review | green head | One independent reviewer reads the diff. | No blocking finding on the current head |
| Merge | reviewed green head | Merge, then delete the branch and its worktree. | Issue closed |

An item that cannot advance gets `needs-human` and a comment naming the blocker. Continue with other items.

## Token Rules

- One work item per session. Start it fresh; do not carry another item's conversation.
- Load only the item, its spec section, and the files it names. Locate anything else by search, not by reading directories.
- Never ask a model what a compiler, linter, test, `git`, or `gh` can answer.
- Keep tool output out of context. Send check output to a file and read the summary; on failure read only the failing section.
- Do not review a red head. Fix it first.
- Use one reviewer per head, from a different vendor or model than the author, for example `codex review --base <branch>` on Claude's diff. Give it the base and head commits and the spec section, nothing else. After a fix, review only what changed.
- No fan-out by default. Use a panel, parallel agents, or a second reviewer only when the spec leaves a decision with two or more workable options and reversing it later is expensive.
- Route by need. Raise the model or effort only after a failed attempt, and say why.

  | Work | Model | Effort |
  |---|---|---|
  | Spec, critical decision | strongest | high |
  | Implementation, review | mid-tier | medium |
  | Rename, format, conflict merge, log triage | smallest, or a subagent on it | low |

- Wait without spending turns. Block once on `gh pr checks <n> --watch --fail-fast >/dev/null`, then read `gh pr checks <n>` once.
- Cap unattended runs, for example `claude -p --model <m> --effort <e> --max-budget-usd <n>`.
- Stop after three fix cycles on one item. Label it `needs-human` and report the blocker; do not restart the count.

## Acceptance Tests

- Write them in the Spec state from the requirement, before the implementation exists, and confirm they fail.
- The implementing session does not edit, skip, or weaken them. If one is wrong, send the item back to Spec.
- Where the repository allows it, enforce this in CI: fail a pull request that changes an acceptance test path unless it carries `spec-change`.
- Every bug fix adds a regression that fails on the base and passes on the head.

## Decisions

Decide reversible questions yourself, record the choice and its reason in the pull request, and continue. Stop and ask the user, and do not merge, when the item involves any of these:

- Loss or migration of production data, or anything that cannot be undone.
- Authentication, authorization, secrets, or a trust boundary.
- Spending money, deploying, releasing, or publishing.
- Agent instructions, permission settings, CI gates, or check allowlists.
- A requirement that contradicts another requirement or the user's stated intent.

Ask with one question that states the decision, the options, and what each option costs. If no question tool is available, label the item `needs-human` and stop that item only.

## Evidence

- The pull request description carries an artifact that settles its claims: the commands run and their actual output, bound to the head commit. A summary or an agent's statement that it works is not an artifact.
- Report each check as `PASS(scope, evidence)`, `FAIL(reason)`, `NOT_RUN(reason)`, or `NOT_APPLICABLE(reason)`. Agreement among agents is not evidence.
- Update a pull request by adding commits and comments. Do not rewrite its description or history to hide an earlier state.

## Outer Loop

Run this when asked, or after about ten merged items. It changes the factory, not the product.

- Collect from merged pull requests: review findings, fix cycles per item, and every `needs-human` cause.
- Turn a finding seen twice into a deterministic check such as a lint rule, test, CI step, or hook. Then delete the instruction text it replaces.
- Turn a question asked twice into a recorded decision in the repository's instructions or spec.
- Remove instructions, skills, and plugins that nothing triggered. Compare `/usage` and `/context` before and after, and keep a change only if usage drops without more rework.
- Changes to instructions, settings, or gates go in their own pull request for the user to merge.
