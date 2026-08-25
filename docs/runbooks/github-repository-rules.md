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
- `web-e2e`
- `admin-flutter`
- both `container-build` matrix checks
- `ops-config`
- `branch-and-pr-title`
- `commits`
- `gitleaks`
- `trivy-repository`
- `dependency-review`
- `Analyze (java-kotlin)`
- `Analyze (javascript-typescript)`

Add a branch-name restriction matching the same convention enforced in `.github/workflows/policy.yml` if your GitHub plan/repository ruleset options expose that control.

Add commit metadata rules for Conventional Commits only if they fit your chosen squash strategy. If squash merging is mandatory, validating PR titles plus individual PR commits in CI is usually easier to understand and maintain.


## Release tag ruleset

Create a second ruleset targeting tags matching `v*.*.*`. Block force updates and deletion. In a multi-person repository, restrict tag creation/bypass to the release-maintainer role; in this portfolio repository, keep the rule enabled so accidental retagging is visible and deliberate. The release and promotion workflows independently reject a tagged commit that is not reachable from `main`, and promotion also detects a moved tag because the manifest source revision must match the currently resolved tag commit.

## Protected environments

Create GitHub Environments named `staging`, `production` and `mobile-release`. Keep environment-scoped URLs/secrets out of repository variables when they are deployment credentials. Require an approval boundary for production/mobile release when the repository has another trusted reviewer, and prevent environment bypass except for an explicit incident procedure. The provider-neutral workflows are designed so environment approval authorizes immutable release coordinates rather than rebuilding source.
