---
name: dolpa-swarm
description: Run one large issue or epic as parallel dolpa lanes. Slice it into items, schedule lanes that cannot collide, and merge one at a time, with a coordinator that reads only `gh` state. Use for "dolpa swarm", "스웜", or an epic too large for one dolpa run. Do not use for a single item or for gathering several opinions on one decision.
---

# Dolpa Swarm

Run many items of one epic through `dolpa` at once. Each worker follows the `dolpa` skill unchanged; this skill only decides what runs when. Repository instructions and the user's standing approvals outrank both skills.

Parallel work does not lower what an item costs. It shortens the wait, and every conflict, duplicate, or rebase it causes is paid for twice. Prefer fewer lanes that never collide over more lanes that do.

## Roles

| Role | Does | Reads |
|---|---|---|
| Coordinator | Slices, schedules, starts workers, merges, reports. Writes no product code. | Issue bodies and `gh` JSON fields. Never a diff or a worker's output. |
| Worker | Takes one item through `dolpa` in its own worktree and fresh session. | Its item, its spec section, and the files the item names. |

## Slice

Do this once, on the strongest model, before any worker starts.

- Write the epic's spec, then cut it into items that each pass `dolpa` Intake and its size limit.
- Each item's issue names the paths it may change and the items it depends on. A worker that needs a path outside its list stops and reports; it does not edit that path.
- Give a file that many items must touch, such as registration, routing, schema, or a lock file, to one item scheduled before the others.
- Branch items from the base branch. Stack an item on another only when it needs code that is not merged yet.
- The epic issue lists every item in one line with its lane and state. That list is the only shared memory, so a fresh session can take over as coordinator at any point.

## Lanes

A lane is a chain of items in which each depends on the one before. Items in a lane run one after another; lanes run side by side.

- Two lanes run together only when their path lists do not overlap. Otherwise join them into one lane.
- Width is the number of lanes running at once: the user's number, else three. It replaces `dolpa`'s in-progress limit for this run. Do not raise it mid-run to catch up.
- Start a lane's next item only after the previous one is merged. Without a standing merge approval, start it after the previous head is reviewed and green, stacked on that head.
- Before starting an item, run `dolpa`'s check for existing work on it.

## Run

- A worker's brief is one line: the item number and "use dolpa". Everything else is in the issue. Do not paste the epic, the plan, or another item's result into it.
- Start workers in the background, for example `claude -p --worktree <item> --model <m> --max-budget-usd <n> "<brief>"`, or as subagents with worktree isolation. One worktree holds one item.
- Wait on completion notices or `gh pr checks <n> --watch`. Do not poll, and do not read a worker's output while it runs.
- A worker ends with at most five lines: item, pull request, state, blocker. Take everything else from `gh pr view <n> --json state,mergeable,statusCheckRollup,labels`.
- After slicing, the coordinator's remaining work is reading JSON and following this list. Run it in a fresh session on a small model.

## Merge

- Merge one pull request at a time, in the order items became reviewed and green. Wait for the base branch to be green before the next merge.
- A running lane updates from the base only when GitHub reports a conflict or when it starts its next item.
- A conflict in a path outside both items' lists means the slicing was wrong. Stop both lanes and correct the path lists before resolving it.
- Remove each item's branch and worktree when it merges.

## Stop

- An item that reaches a `dolpa` decision gets `needs-human`. Its lane stops; other lanes continue.
- Stop the whole swarm when the base branch is red, when two items in a row fail for the same cause, or when the budget the user set is spent.
- Do not restart a stopped item in another lane to get around its block.

## Report

End with one table built from `gh`, not from memory: item, lane, pull request, state, fix cycles. Put `needs-human` items first with the question each one needs answered, then the pull requests the user reads before merge.
