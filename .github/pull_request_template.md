## What changed?

<!-- Explain the user/business/engineering outcome, not only the files changed. -->

## Why?

<!-- Link issue/ADR if relevant. -->

## How was it verified?

- [ ] Backend tests
- [ ] Public web lint/build
- [ ] Browser E2E/Lighthouse, if customer experience is affected
- [ ] Production container build, if runtime/dependencies are affected
- [ ] Flutter analyze/test, if affected
- [ ] Manual smoke test, if appropriate

## Risk and rollback

<!-- What can fail? How would we detect and revert/mitigate it? -->

## Architecture / security / operations

- [ ] No architectural decision requires a new or updated ADR
- [ ] No secrets or credentials are included
- [ ] Database migration is safe and forward-only, if applicable
- [ ] Logging/metrics/runbook impact considered, if applicable
- [ ] Administrator mutations are audited, or the PR explains why audit does not apply
- [ ] Public-content changes preserve the documented cache-freshness contract

## Screenshots

<!-- UI changes only. -->
