# Contributing

## Workflow

1. Create or link an issue.
2. Branch from `main` using the repository branch naming convention.
3. Keep changes small and cohesive.
4. Add or update tests and documentation.
5. Run the local checks before pushing.
6. Open a pull request and complete the template.
7. Merge only when required reviews and checks pass.

## Definition of done

A change is done when:

- acceptance criteria are met;
- tests cover important behavior;
- lint/static analysis is clean;
- API/database changes are backward-compatible or documented;
- migrations are forward-only and reviewed;
- security impact has been considered;
- operational impact and rollback are documented when relevant;
- administrator mutations preserve audit coverage and public mutations preserve cache-freshness behavior;
- ADRs are added or updated for material architectural decisions.
