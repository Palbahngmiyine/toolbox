# Outer Loop

This changes the line, not the product.

- Collect from merged pull requests: review findings, fix cycles per item, and every `needs-human` cause.
- Turn a finding seen twice into a deterministic check such as a lint rule, test, CI step, or hook. Then delete the instruction text it replaces.
- Turn a question asked twice into a recorded decision in the repository's instructions or spec.
- Remove instructions, skills, and plugins that nothing triggered. Compare `/usage` and `/context` before and after, and keep a change only if usage drops without more rework.
- From the design panels, compare how often they converged, which vendor's shape won or was grafted, and fix cycles after Spec. When panels mostly converge, or a seat neither wins nor is grafted, propose dropping that seat or narrowing the trigger.
- Change an instruction, setting, or gate only with evidence that the same failure happened at least twice, in its own draft pull request for the user to merge, not on the day it was opened.
