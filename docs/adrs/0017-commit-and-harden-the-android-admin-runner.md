# ADR 0017: Commit and harden the Android admin runner

- Status: Accepted
- Date: 2026-08-24

## Context

The Flutter administrator application had production Dart code, OIDC/PKCE authentication and CI analysis/tests, but no committed Android host project. A clone therefore could not build or run the native application without first regenerating platform files with a local Flutter SDK. That left the OIDC callback, Android application identifier, network-security policy, backup behavior and release-signing behavior outside normal code review.

The admin app uses `flutter_appauth` 12.x, whose Android support requires API 24 or newer and an AppAuth redirect-scheme manifest placeholder. Local development uses HTTP through `adb reverse`, while non-local environments must use HTTPS.

## Decision

Commit `admin-flutter/android/` as repository-owned production code.

The runner:

1. uses application/namespace `dev.cinnamonandclay.admin`;
2. requires Android API 24 or newer;
3. configures the lowercase `dev.cinnamonandclay.admin` AppAuth callback scheme used by Keycloak;
4. disables Android application backup and explicitly excludes app data from cloud/device-transfer backup rules;
5. denies cleartext traffic in the main application and permits it only through a debug-only manifest/network-security override;
6. refuses release tasks when signing material is absent, unless an explicit diagnostics-only override is supplied;
7. reads signing material only from process environment variables and never from repository files;
8. keeps local API/OIDC endpoints in Dart defines rather than native source;
9. validates non-local Dart configuration at application startup so production/staging API and issuer URLs must use HTTPS, and release builds must declare a non-local environment explicitly;
10. pins the Gradle distribution version and SHA-256 while allowing Flutter to inject its SDK-owned wrapper launcher/JAR when absent;
11. adds CI coverage for debug APK assembly, the packaged AppAuth callback, a signed release AAB and an emulator launch smoke;
12. creates provenance-attested Android release bundles with a checksum and machine-readable release manifest.

Flutter 3.47.1 Android tooling is the baseline for the committed runner and native CI. The project retains the compatibility flags for legacy Kotlin/AGP DSL behavior until every native dependency is deliberately verified for built-in Kotlin/new DSL migration.

## Consequences

A clean clone can now run `flutter build apk` without regenerating Android source. Flutter may inject its standard `gradlew` launchers and wrapper JAR from the installed SDK cache; those generated launcher artifacts are ignored, while `gradle-wrapper.properties` remains repository-owned, version-pinned and checksum-pinned. Native security configuration and dependency-toolchain changes are reviewable in pull requests.

The repository still does not contain a production signing key. Production mobile releases require the protected `mobile-release` GitHub Environment and its keystore secrets. CI generates an ephemeral keystore only to prove that the signing path compiles and produces a signed bundle.

The emulator smoke proves native launch and callback registration, but it does not automate credentials in an external system browser. A real local Keycloak login remains a human-in-the-loop smoke because automating administrator credentials through Chrome would create a brittle test and encourage credential handling in CI.
