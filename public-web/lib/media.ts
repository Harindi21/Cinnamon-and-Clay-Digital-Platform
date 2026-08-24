import { backendGet } from '@/lib/backend';

export type MediaAsset = {
  id: string;
  url: string;
  alt: string;
  caption: string;
  focalXPercent: number;
  focalYPercent: number;
  width: number | null;
  height: number | null;
  version: number;
};

export type PublicMedia = {
  hero: MediaAsset | null;
  about: MediaAsset | null;
  gallery: MediaAsset[];
};

export function getPublicMedia(): Promise<PublicMedia> {
  return backendGet<PublicMedia>('/api/v1/media', 'media');
}

export function mediaSrc(asset: MediaAsset): string {
  return `/media/${encodeURIComponent(asset.id)}?v=${asset.version}`;
}

export function objectPosition(asset: MediaAsset): string {
  return `${clampPercent(asset.focalXPercent)}% ${clampPercent(asset.focalYPercent)}%`;
}

function clampPercent(value: number): number {
  return Math.min(100, Math.max(0, Number.isFinite(value) ? value : 50));
}
