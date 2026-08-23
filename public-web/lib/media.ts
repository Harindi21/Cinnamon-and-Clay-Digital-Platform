import { backendGet } from '@/lib/backend';

export type MediaAsset = {
  id: string;
  url: string;
  alt: string;
};

export type PublicMedia = {
  hero: MediaAsset | null;
  about: MediaAsset | null;
  gallery: MediaAsset[];
};

export function getPublicMedia(): Promise<PublicMedia> {
  return backendGet<PublicMedia>('/api/v1/media');
}

export function mediaSrc(asset: MediaAsset): string {
  return `/media/${encodeURIComponent(asset.id)}`;
}