import type { MediaAsset, PublicMedia } from '@/lib/media';

const demoAsset = (
  id: string,
  url: string,
  alt: string,
  caption: string,
  focalXPercent = 50,
  focalYPercent = 50
): MediaAsset => ({
  id,
  url,
  alt,
  caption,
  focalXPercent,
  focalYPercent,
  width: null,
  height: null,
  version: 1
});

const DEMO_HERO = demoAsset(
  'demo-hero',
  'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=1800&q=85&auto=format&fit=crop',
  'Warm cafe interior with tables and natural light',
  'A warm corner for slow coffee and good company.',
  50,
  48
);

const DEMO_ABOUT = demoAsset(
  'demo-about',
  'https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=1200&q=85&auto=format&fit=crop',
  'Cafe counter and seating area',
  'Built around coffee, bakes and unhurried conversations.'
);

const DEMO_GALLERY = [
  demoAsset(
    'demo-gallery-coffee-cup',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=1200&q=85&auto=format&fit=crop',
    'Cup of freshly brewed coffee on a cafe table',
    'Coffee made for slow mornings.',
    50,
    52
  ),
  demoAsset(
    'demo-gallery-pour-over',
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200&q=85&auto=format&fit=crop',
    'Coffee being prepared by hand',
    'Care in every pour.',
    52,
    48
  ),
  demoAsset(
    'demo-gallery-table',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200&q=85&auto=format&fit=crop',
    'Cafe table prepared for food and drinks',
    'A table worth lingering around.'
  ),
  demoAsset(
    'demo-gallery-beans',
    'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=1200&q=85&auto=format&fit=crop',
    'Roasted coffee beans ready for brewing',
    'Fresh beans, carefully brewed.'
  ),
  demoAsset(
    'demo-gallery-latte',
    'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=1200&q=85&auto=format&fit=crop',
    'Milk coffee served in a ceramic cup',
    'Comfort in a cup.',
    50,
    55
  ),
  demoAsset(
    'demo-gallery-brunch',
    'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=1200&q=85&auto=format&fit=crop',
    'Brunch dishes arranged on a shared table',
    'Something warm to go with your coffee.',
    50,
    52
  )
] as const;

/**
 * Keep the real platform media model intact while making a fresh local clone
 * look like the original static Cinnamon & Clay prototype before an editor has
 * uploaded media. Production continues to respect the CMS/media state unless
 * DEMO_MEDIA_FALLBACK_ENABLED=true is explicitly supplied.
 */
export function withDemoMediaFallback(media: PublicMedia): PublicMedia {
  if (!demoFallbackEnabled()) {
    return media;
  }

  return {
    hero: media.hero ?? DEMO_HERO,
    about: media.about ?? DEMO_ABOUT,
    gallery: media.gallery.length > 0 ? media.gallery : [...DEMO_GALLERY]
  };
}

function demoFallbackEnabled(): boolean {
  const configured = process.env.DEMO_MEDIA_FALLBACK_ENABLED?.trim().toLowerCase();

  if (configured === 'true') {
    return true;
  }

  if (configured === 'false') {
    return false;
  }

  return process.env.NODE_ENV !== 'production';
}
