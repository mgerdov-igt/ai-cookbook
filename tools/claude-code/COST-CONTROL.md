# Claude Code Cost and Token Control

## Match model strength to phase

- Use a strong reasoning model for ambiguous analysis.
- Use a coding or balanced model for repeated code changes and tests.
- Return to a stronger model only for final risk review when needed.

## Keep sessions compact

- Repeat the goal and next step in a short note after each step.
- Start a fresh session after major milestones.
- Avoid pasting full raw logs when filtered excerpts are enough.

## Bound iterative work

- Set explicit stop conditions.
- Ask for coverage/test deltas after each batch.
- Require the model to explain why the next iteration is needed.
