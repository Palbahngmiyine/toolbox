# Design Panel

Read this in the Spec state only when the spec leaves a decision with two or more workable options and reversing it later is expensive. Otherwise write the design note alone. Repository instructions and the user's standing approvals outrank this file.

The panel pays for three short, independent sketches so that no fix cycle later pays for a wrong shape. It touches no code and adds no file to the repository.

## Seats

Three vendors, such as Claude, OpenAI, and Google, each write one candidate. After that each vendor takes a different role, so use stays even and the judge and the reviewer never share a vendor with this session:

| Role | Who |
|---|---|
| Candidate | All three vendors, one seat each |
| Synthesizer | This session. It frames, reads, decides, and grafts. |
| Judge | The vendor that is neither this session's nor the one `dolpa` Review will try first. With a Claude session and `codex review` first, Gemini judges. |
| Reviewer | Unchanged, as `dolpa` Review sets out |

## Frame

Write one brief; it is every candidate's whole input.

- The decision in one sentence, the constraints, the acceptance criteria, and the paths of the spec section and the files it names. Do not paste repository content, since each CLI reads the tree. Do not say which option you favor.
- Ask for at most 80 lines and no implementation code: types and signatures, module boundaries and the one owner of each piece of state, one line tracing the main input through them, the alternative rejected and why, and the riskiest assumption with one command that would disprove it.

Write the rubric apart from the brief, and do not show it to candidates: three to five criteria taken from the acceptance criteria, then these tiebreaks in order: each piece of state has one owner, callers need to know least, and the shape is cheapest to reverse.

## Fan out

Start all three at once, read-only, each writing to its own file outside the repository, with the strongest model and high effort per the `dolpa` routing table:

- `claude -p --permission-mode plan --model <m> --effort high --max-budget-usd <n> "$BRIEF" > claude.md`
- `codex exec -s read-only -m <m> -o codex.md "$BRIEF"`
- `gemini -p "$BRIEF" --approval-mode plan -m <m> > gemini.md`

A seat that exits non-zero, reports a usage limit, or returns nothing has not answered: do not retry or wait, as in `dolpa` Review. Two answers still make a panel. With fewer, write the note alone and record why the panel did not run.

## Converge or Judge

Read every answer in full and score each against the rubric, criterion by criterion.

- Converged: the same module boundaries and state owners, whatever the names. Take that shape and skip the judge. Agreement is not evidence, so the probe below still runs.
- Diverged on the solution: copy the answers to labels `A`, `B`, `C` in shuffled order with vendor names removed, and keep the map to yourself. Start the judge in a fresh process with only the rubric and the labeled answers. It returns a score per criterion per label and one recommended base, nothing else. When it agrees with you, that is the base. When it does not, reread both picks' rejected alternatives, decide, and record why.
- Diverged on what the problem is: the brief was under-specified. Fix it and run the panel once more. A second divergence goes to the user as one question with the two leading shapes and what each costs.

## Graft and Prove

- Take at most two parts from each losing answer that strengthen the base, and rewrite them in the base's terms. Do not paste.
- Run the base's disproving command. If it disproves the assumption, drop that base and probe the next-ranked one. If none survives, mark the item `needs-human`.
- Put the result where `dolpa` already keeps it: the shape in the spec's design note, acceptance tests written from it, and the runner-up shape as one of the pull request's decisions made on the user's behalf, with the spec line that reverses it. Note on the item which seats answered, whether it converged, the winning vendor, and the grafts.
