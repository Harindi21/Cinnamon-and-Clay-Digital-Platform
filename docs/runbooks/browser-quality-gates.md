# Browser E2E, accessibility and performance gates

The `web-e2e` CI job tests the built Next.js application in real Chromium. A deterministic stdlib Python server implements the public REST contract so browser failures are attributable to the web layer rather than Docker/identity/storage startup noise. Spring/Testcontainers tests remain the authority for backend behavior.

The browser suite verifies:

- server-rendered menu/content/contact/reviews/media data;
- the real Next.js media proxy and security/cache headers;
- gallery lightbox open/close, Arrow/Home/End/Escape behavior and focus restoration;
- public-web readiness reporting;
- a mobile viewport without horizontal overflow.

Lighthouse then enforces repository budgets against the same built application:

- accessibility >= 0.95;
- best practices >= 0.90;
- SEO >= 0.90;
- performance >= 0.75;
- LCP <= 3.5 seconds in the CI profile;
- CLS <= 0.10;
- total transfer <= 1.6 MB.

These are regression gates, not claims about real-user production Core Web Vitals. Production performance should eventually be calibrated from RUM/telemetry.

See `tests/e2e/README.md` for local execution. Lighthouse artifacts and failing service logs are retained by GitHub Actions for diagnosis.
