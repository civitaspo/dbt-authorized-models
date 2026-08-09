# Securefix setup

This repository uses [`csm-actions/securefix-action`](https://github.com/csm-actions/securefix-action) and related CSM actions so pull request workflows can request signed commits, approvals, and releases without holding strong credentials.

The shared server repository is [`civitaspo/securefix-server`](https://github.com/civitaspo/securefix-server).

## GitHub Apps

Install both apps on this repository and on `civitaspo/securefix-server`:

- Client app: `issues: write` (creates request labels on the server repo)
- Server app: `contents: write`, `actions: read`, `pull_requests: write`, and `workflows: write`

`workflows: write` is required because this repository allows Securefix to update files under `.github/workflows`.

## Variables and secrets (this repository)

- Variable `SECUREFIX_CLIENT_APP_ID`
- Secret `SECUREFIX_CLIENT_PRIVATE_KEY`
- Variable `SECUREFIX_SERVER_REPOSITORY` (value: `securefix-server` — repository name only; `securefix-action` expects this format)

Strong secrets (GPG keys, machine-user PAT, server app private key) live only in `civitaspo/securefix-server`.

## Flows

### Lint autofix (Securefix)

The `Lint` workflow runs the workflow fixers as separate steps. When a pull request needs fixes, it requests a Securefix commit. The server workflow accepts client workflows named `Lint` and `Release PR`.

### Auto-approval

The `Approve Request` workflow asks the server to approve pull requests authored by `civitaspo`, `renovate[bot]`, `dependabot[bot]`, or `civitaspo-securefix-server[bot]` (and on `/approve` comments from `civitaspo`). Both the client and server actions validate that all commits are signed and that committers are in `allowed_committers` (defaults are only Renovate/Dependabot; this repository also passes `civitaspo`, `cursoragent`, and `civitaspo-securefix-server[bot]`). When client validation passes, it creates a label on `securefix-server`; the server then approves with the machine-user PAT (`civitaspo-bot`).

## Dependency updates

- **Version updates:** [Renovate](https://docs.renovatebot.com/) (`renovate.json5`) owns GitHub Actions and mise tooling. Non-major updates automerge when checks pass.
- **Dependabot version updates:** Not configured. There is no `.github/dependabot.yml`.
- **Dependabot security updates:** May remain enabled via the GitHub repository security settings. Those PRs are eligible for Approve Request because `dependabot[bot]` is listed in the workflow `if:` and in `allowed_committers`.

### Release

1. The `Release PR` workflow asks Securefix to open or update `release/next` with changelog and version metadata.
2. After that PR is squash-merged, the `Release Tag` workflow creates an annotated tag and requests a server-side release.
3. The server publishes the GitHub Release for the tag.

See [releasing.md](releasing.md).
