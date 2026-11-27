# Before and After Visuals

Read this when building the `## Before and after` section. Work from what the session already loaded; start no explorer or second model for it.

## The case

- Pick one case the user would recognize: a real input, command, request, or action. State it in one sentence under the heading. The table and the visual follow that case and nothing else.
- A table row names one thing the user observes, then its value before and after: the output, the state, the count, the time, the error text. Leave out what did not change.
- Take both values from a run, the before one on the base commit. A value that was not observed is marked `NOT_RUN(reason)`.

## UI change

- Capture the before state on the base commit and the after state on the head with the same steps, route, viewport, theme, and data, and stop both at the same step.
- Prefer a recording of the interaction: 20 seconds at most, `.mp4`, `.mov`, or `.webm`, under 10 MB. Use a recorder the repository or machine already has. Fall back to one screenshot per state only when the screen cannot be recorded.
- Put the two screenshots in one table row, before on the left, and say in one line where to look.
- Show real output. A mock-up or an edited capture is not a screenshot. When the screen cannot be run, write `NOT_RUN(reason)` under the heading and draw the image below instead.

## Any other change

Draw one PNG, 1600×900, that a reader understands without the code.

- Top left: a one-line title that names the case, and one sentence under it. Bottom: one sentence that states the difference in the result.
- Two panels, before on the left and after on the right, labeled in the user's language. Each follows the case from top to bottom in the same number of rows, five at most: what goes in, each step it passes, what comes out.
- Row N on the left is the counterpart of row N on the right. A step that exists on one side only leaves an empty dashed slot on the other, labeled as absent.
- The last row of each panel is the result the user gets, with the observed value.
- Each changed part carries one short line that says what differs from its counterpart.
- Rows are rounded cards joined by thin arrows, each a real module, function, state, or number, named in plain words. Short facts inside a card are chips.
- When nothing existed before, the before panel shows what the user had to do without the change.

| Role | Fill | Border or text |
|---|---|---|
| Page | `#fafafa` | |
| Card, panel | `#fcfcfc` | `#e8e8e8` |
| Chip | `#f2f2f2` | `#e8e8e8` |
| Changed part, after panel only | `#c2e7ff` | `#baddf5` |
| Its counterpart in the before panel, and an absent slot | `#fcfcfc` | `#666666`, dashed |
| Text | | `#1f1f1f` |
| Secondary text, arrows | | `#666666` |
| Small label above a panel or row | | `#1f6f9a` |

- Use no other color. Only what the change touches carries `#c2e7ff`.
- Write one self-contained HTML file with system fonts and no network request, and screenshot it with a headless browser the machine already has, such as `chrome --headless --screenshot=<out>.png --window-size=1600,900 <file>.html`. Install nothing for it. With no such browser, write the same layout as an `.svg`.
- Open the image once and fix text that is clipped or overlaps.

## Upload

- Keep the body file and the media in one temporary directory outside the repository. Commit none of it.
- Reference each image in the body as `![alt](./name.png)` and pass every file with `gh pr create --attach <file>`; `gh` rewrites the reference to the uploaded asset.
- A recording has no reference. `gh` appends it after the body, so attach the before recording first and say under the heading which is which.
- When a later commit changes what the visual shows, post the new one with `gh pr comment <n> --attach <file>`.
