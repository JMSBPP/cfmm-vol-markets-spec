# Agent instructions — scratchpad TODO → GitHub

When working open items in `TODO.md` (section **Open**, not marked Done), follow this workflow for **each** item:

## 1. Classify

Assign a conventional type from the item’s nature:

| Type | Use when |
|------|----------|
| `feat` | New capability, types, formulas, constructors |
| `fix` | Bug / incorrect behavior |
| `docs` | Documentation, brainstorm write-ups, README-only |
| `chore` | Hygiene, commits, tooling, non-product moves |
| `refactor` | Rename / package move / reshape without new behavior |
| `test` | Tests-only |
| `spike` | Time-boxed investigation (answer, not keep code) |

## 2. Create a branch

```bash
git checkout main
git pull
git checkout -b <type>/todo-<N>-<short-slug>
```

Examples: `feat/todo-5-param-fee-capture`, `refactor/todo-10-panoptic-package`.

## 3. Create a GitHub issue

Write the TODO item body into the issue (title + full open-item text). Label or title-prefix with the type, e.g. `[feat] TODO #5: …`.

```bash
gh issue create --title "[<type>] TODO #<N>: <short title>" --body "$(cat <<'EOF'
## TODO.md item #<N>

<paste open item>

## Type
`<type>`

EOF
)"
```

## 4. Open a PR (branch → `main`)

Commit work (or a tracking stub if implementation is not started). Push and open PR targeting `main`.

PR body **must** reference the issue:

```markdown
## Summary
- Implements / tracks TODO.md #<N> (<type>)

## Linked issue
Solves #<ISSUE_NUMBER>

## Test plan
- [ ] …
```

```bash
git push -u origin HEAD
gh pr create --base main --title "<type>(todo-<N>): <short title>" --body "…"
```

## 5. Cross-comments (required)

After the PR exists:

1. **On the PR:** comment that it solves the issue, e.g. `Solves #<ISSUE_NUMBER>`.
2. **On the issue:** comment that resolution is on the PR, e.g. `Solving on PR #<PR_NUMBER>`.

```bash
gh pr comment <PR_NUMBER> --body "Solves #<ISSUE_NUMBER>"
gh issue comment <ISSUE_NUMBER> --body "Solving on PR #<PR_NUMBER>"
```

Prefer also `Fixes #<ISSUE_NUMBER>` / `Closes #<ISSUE_NUMBER>` in the PR body when the PR fully completes the item.

## 6. Update `TODO.md`

When the PR merges and the item is done, move it under **Done** (strike-through) and record issue + PR URLs.


---
This file mirrors `AGENTS.md` for Qwen agents.
