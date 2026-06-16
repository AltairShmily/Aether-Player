# Contributing to Aether Player

Thanks for your interest in contributing! Here's a quick guide to get started.

## Branch Strategy

- **`main`** — Stable release branch. All PRs targeting `main` require review.
- **`dev`** — Active development branch. Create feature branches from `dev`.

```
dev  ←── feature/your-feature
         ↓ PR
dev  ←── merge
         ↓ PR (when ready)
main ←── release
```

## Commit Convention

Use a **type prefix** with an optional emoji for clear, scannable history:

| Emoji | Type       | Usage                              |
| ----- | ---------- | ---------------------------------- |
| ✨    | `feat`     | New feature                        |
| 🐛    | `fix`      | Bug fix                            |
| 📝    | `docs`     | Documentation only                 |
| ♻️    | `refactor` | Code restructuring (no behavior change) |
| ✅    | `test`     | Adding or updating tests           |
| 🔧    | `chore`    | Build, CI, tooling                 |
| 🎨    | `style`    | Code style / formatting            |

**Format:** `<emoji> <type>(<scope>): <description>`

Examples:
```
✨ feat(player): add subtitle track selector
🐛 fix(auth): handle expired token refresh
📝 docs: update README build instructions
✅ test(handler): add library endpoint tests
```

## Pull Request Workflow

1. **Fork & branch** — Create a feature branch from `dev`.
2. **Develop** — Write code, add tests, ensure `go test ./...` and `flutter test` pass locally.
3. **Lint** — Run `go vet ./...` (backend) and `flutter analyze` (frontend).
4. **Commit** — Follow the commit convention above.
5. **Push & PR** — Open a PR against `dev`. Fill in the PR template.
6. **Review** — Address feedback. CI must pass before merge.
7. **Merge** — Squash merge into `dev`.

## Development Setup

See the [README](README.md#Getting-Started) for prerequisites and build instructions.

## Questions?

Open a discussion or issue on GitHub. We're happy to help!
