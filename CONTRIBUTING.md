# Contributing to Hop Tales

## Setup

```sh
brew install swiftlint   # the hooks and the build both use it
./scripts/setup-git.sh   # commit template + hooks, once per clone
open HopTales.xcworkspace # not the .xcodeproj
```

## Style

SwiftLint runs in two places: a build phase surfaces warnings in the issue navigator while you
work, and a `pre-commit` hook **blocks** a commit whose staged Swift files do not lint. The hook
runs `--strict`, so the config is the only thing that decides what matters — if a rule is on, it
blocks.

Most of it fixes itself:

```sh
swiftlint --fix && git add -u
```

`.swiftlint.yml` is the house style: two-space indentation, lines wrapped at 100, imports
alphabetised. If a rule is wrong for this codebase, change the config in the same pull request
rather than sprinkling `swiftlint:disable`.

Without SwiftLint installed the hook warns and lets the commit through, so a fresh clone is never
blocked by a missing tool.

## Commits

Subjects follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>[(scope)][!]: <description>

[body]

[footers]
```

A `commit-msg` hook rejects anything else, and tells you which rule you broke. `git commit
--no-verify` skips it when you genuinely need to.

### Subject

- **Lowercase**, no full stop, **72 characters or fewer**.
- Present tense, describing what the commit does: *pin the current word*, not *pinned* or *pins*.
- `!` before the colon marks a breaking change, and the body must then carry a `BREAKING CHANGE:`
  footer saying what breaks and what to do instead.

| Type | For |
|---|---|
| `feat` | a capability the child or the parent can now use |
| `fix` | a defect in behaviour that shipped |
| `docs` | documentation only, including `docs/HANDOFF.md` and `CLAUDE.md` |
| `style` | formatting with no change in behaviour |
| `refactor` | neither fixes a defect nor adds a capability |
| `perf` | makes it faster or lighter |
| `test` | tests and snapshot references only |
| `build` | `project.yml`, `Package.swift`, signing, dependencies |
| `ci` | `ci_scripts`, Xcode Cloud, anything about how builds run |
| `chore` | everything else with no product effect |
| `revert` | undoes an earlier commit |

Scopes are optional and name an area, not a file: `reading`, `speech`, `world`, `home`, `content`,
`design`, `app`, `project`, `ci`, `deps`. Omit the scope when a change genuinely spans the app.

### Body

The subject says what; **the body says why**. The diff already covers what changed, so spend the
body on the reasoning a reviewer cannot reconstruct — the constraint you were working around, the
option you rejected, the spec line you deliberately departed from.

```
fix(speech): require a token in two partials before it counts

A single frame of recognition is often a misfire, and a misfire moves the ball
under a child who did not read the word. Two consecutive partials cost about
80ms, which is below what anyone notices.

Closes #12
```

Reference issues in a footer: `Closes #12`, `Part of #29`.

## Pull requests

`main` is protected and takes squash merges only, so **the pull request title becomes the commit on
`main`** — it has to satisfy the same rules as a commit subject.

Keep a pull request to one issue. `.github/pull_request_template.md` is the shape: the issue it
closes and a few bullets on what the change is, sized to the work. Spec changes and anything that
needs a device get a section only when there are some. The reasoning, trade-offs and test results
go in the commit messages, not the description.

## Before you open one

- `xcodegen generate` if you added files or targets, and commit the regenerated `.xcodeproj`.
- All tests green through the `HopTales` scheme.
- Re-record snapshot references if the UI legitimately changed, and say so in the commit.
- `docs/HANDOFF.md` is the spec. If the code has to differ from it, amend the spec in the same pull
  request and list the change under "Spec changes" — a spec that quietly disagrees with the app is
  worse than no spec.
