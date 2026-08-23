# GitHub repository rules

Create a ruleset targeting the default branch `main`.

Recommended settings for this repository:

- Restrict deletions.
- Block force pushes.
- Require a pull request before merging.
- Require at least 1 approval. Use 2 in a real multi-person team for high-risk repositories.
- Dismiss stale approvals when new commits are pushed.
- Require review from CODEOWNERS.
- Require conversation resolution.
- Require status checks before merging.
- Require branches to be up to date before merging, or use a merge queue if you enable one later.
- Require linear history and use squash merge for a clean reviewable history.
- Require signed commits if your local setup supports it consistently.

Required checks once they have run at least once:

- `backend`
- `public-web`
- `admin-flutter`
- `branch-and-pr-title`
- `commits`
- `gitleaks`
- `trivy-repository`
- `dependency-review`
- `Analyze (java-kotlin)`
- `Analyze (javascript-typescript)`

Add a branch-name restriction matching the same convention enforced in `.github/workflows/policy.yml` if your GitHub plan/repository ruleset options expose that control.

Add commit metadata rules for Conventional Commits only if they fit your chosen squash strategy. If squash merging is mandatory, validating PR titles plus individual PR commits in CI is usually easier to understand and maintain.
