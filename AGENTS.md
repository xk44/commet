# AGENTS.md

This file applies to the entire repository.

## Purpose
Follow these practices when making changes in this repo:

## Workflow
- Read `README.md` and `todo.txt` before starting work.
- Prefer the smallest safe change that solves a concrete task.
- Update `todo.txt` statuses when tasks are completed or intentionally deferred.
- Keep commits focused and descriptive.

## Coding best practices
- Match existing code style and naming conventions in each package.
- Avoid broad refactors unless they are required to complete the selected task.
- Add/adjust validation near user input boundaries.
- Prefer explicit error handling and user-facing feedback for recoverable failures.
- Do not add unused dependencies.

## Testing and verification
- Run targeted checks for changed areas first, then broader checks when practical.
- If full test runs are too expensive, document what was run and why.

## Documentation
- Update documentation for behavior changes (README, comments, or nearby docs) when needed.
- Keep TODO entries accurate and actionable.

## Safety
- Never commit secrets, credentials, or machine-specific config.
- Keep platform-specific behavior guarded and backwards-compatible when possible.
