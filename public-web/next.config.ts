import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  poweredByHeader: false,
  turbopack: {
    // The monorepo root has its own lockfile for commit tooling. Explicitly
    // scope Turbopack to this application so Next.js does not infer the wrong
    // workspace root from the parent package-lock.json.
    root: process.cwd()
  }
};

export default nextConfig;
