import type { MetadataRoute } from 'next';

function siteUrl(): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL?.trim().replace(/\/+$/, '') ||
    'http://localhost:3000'
  );
}

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: siteUrl(),
      changeFrequency: 'daily',
      priority: 1
    }
  ];
}
