# Securefix setup

This repository uses `csm-actions/securefix-action` to apply workflow security fixes from pull request CI without giving the pull request workflow a token with `contents: write`.

The shared server repository is `civitaspo/securefix-server`.

## GitHub Apps

Create two GitHub Apps and install both into the server repository and the repositories that should use Securefix:

- Client app: `issues: write`
- Server app: `contents: write`, `actions: read`, `pull_requests: write`, and `workflows: write`

`workflows: write` is required because this repository allows Securefix to update files under `.github/workflows`.

## Variables and secrets

Configure these in each client repository:

- Variable `SECUREFIX_CLIENT_APP_ID`
- Secret `SECUREFIX_CLIENT_PRIVATE_KEY`
- Variable `SECUREFIX_SERVER_REPOSITORY`

Configure these in the server repository:

- Variable `SECUREFIX_SERVER_APP_ID`
- Secret `SECUREFIX_SERVER_PRIVATE_KEY`

## Workflows

The `Lint` workflow runs the workflow fixers as separate steps. When a pull request needs fixes, it requests a Securefix commit.

The server workflow in `civitaspo/securefix-server` receives the request through a `securefix-*` label event and creates the commit with the server app.
