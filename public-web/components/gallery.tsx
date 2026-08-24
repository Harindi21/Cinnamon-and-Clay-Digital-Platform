'use client';

import Image from 'next/image';
import { useEffect, useRef, useState } from 'react';

import { mediaSrc, objectPosition, type MediaAsset } from '@/lib/media';

type GalleryProps = {
  assets: MediaAsset[];
};

const focusableSelector = [
  'button:not([disabled])',
  '[href]',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])'
].join(',');

export function Gallery({ assets }: GalleryProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const dialogRef = useRef<HTMLDivElement>(null);
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const openerRef = useRef<HTMLButtonElement | null>(null);
  const activeAsset =
    activeIndex === null ? null : (assets[activeIndex] ?? null);
  const isOpen = activeAsset !== null;

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    closeButtonRef.current?.focus();

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setActiveIndex(null);
        return;
      }

      if (event.key === 'ArrowLeft') {
        event.preventDefault();
        setActiveIndex((current) =>
          current === null
            ? null
            : (current - 1 + assets.length) % assets.length
        );
        return;
      }

      if (event.key === 'ArrowRight') {
        event.preventDefault();
        setActiveIndex((current) =>
          current === null ? null : (current + 1) % assets.length
        );
        return;
      }

      if (event.key === 'Home') {
        event.preventDefault();
        setActiveIndex(0);
        return;
      }

      if (event.key === 'End') {
        event.preventDefault();
        setActiveIndex(assets.length - 1);
        return;
      }

      if (event.key === 'Tab') {
        trapFocus(event, dialogRef.current);
      }
    };

    window.addEventListener('keydown', onKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isOpen, assets.length]);

  useEffect(() => {
    if (!isOpen) {
      openerRef.current?.focus();
    }
  }, [isOpen]);

  if (assets.length === 0) {
    return null;
  }

  function open(index: number, opener: HTMLButtonElement) {
    openerRef.current = opener;
    setActiveIndex(index);
  }

  function move(delta: number) {
    setActiveIndex((current) => {
      if (current === null) {
        return null;
      }
      return (current + delta + assets.length) % assets.length;
    });
  }

  return (
    <>
      <div className="galleryGrid" role="list" aria-label="Cafe gallery">
        {assets.map((asset, index) => (
          <figure
            className={`galleryItem ${galleryVariant(asset, index)}`}
            key={asset.id}
            role="listitem"
          >
            <button
              className="galleryOpenButton"
              type="button"
              onClick={(event) => open(index, event.currentTarget)}
              aria-label={`Open gallery image ${index + 1} of ${assets.length}: ${asset.alt}`}
            >
              <Image
                src={mediaSrc(asset)}
                alt={asset.alt}
                fill
                sizes="(max-width: 720px) 100vw, (max-width: 1080px) 50vw, 33vw"
                style={{ objectPosition: objectPosition(asset) }}
              />
              <span className="galleryZoomHint" aria-hidden="true">
                View
              </span>
            </button>
            {asset.caption && <figcaption>{asset.caption}</figcaption>}
          </figure>
        ))}
      </div>

      {activeAsset && activeIndex !== null && (
        <div
          ref={dialogRef}
          className="galleryLightbox"
          role="dialog"
          aria-modal="true"
          aria-label={`Gallery image ${activeIndex + 1} of ${assets.length}`}
          onMouseDown={(event) => {
            if (event.currentTarget === event.target) {
              setActiveIndex(null);
            }
          }}
        >
          <div className="galleryLightboxChrome">
            <p aria-live="polite">
              {activeIndex + 1} / {assets.length}
            </p>
            <button
              ref={closeButtonRef}
              type="button"
              onClick={() => setActiveIndex(null)}
              aria-label="Close gallery"
            >
              Close
            </button>
          </div>

          <div className="galleryLightboxBody">
            {assets.length > 1 && (
              <button
                className="galleryLightboxNav galleryLightboxPrev"
                type="button"
                onClick={() => move(-1)}
                aria-label="Previous image"
              >
                ‹
              </button>
            )}

            <figure className="galleryLightboxFigure">
              <div className="galleryLightboxImage">
                <Image
                  src={mediaSrc(activeAsset)}
                  alt={activeAsset.alt}
                  fill
                  priority
                  sizes="96vw"
                  style={{ objectPosition: objectPosition(activeAsset) }}
                />
              </div>
              {(activeAsset.caption || activeAsset.alt) && (
                <figcaption aria-hidden={!activeAsset.caption}>
                  {activeAsset.caption || activeAsset.alt}
                </figcaption>
              )}
            </figure>

            {assets.length > 1 && (
              <button
                className="galleryLightboxNav galleryLightboxNext"
                type="button"
                onClick={() => move(1)}
                aria-label="Next image"
              >
                ›
              </button>
            )}
          </div>
        </div>
      )}
    </>
  );
}

function trapFocus(event: KeyboardEvent, dialog: HTMLDivElement | null) {
  if (!dialog) {
    return;
  }

  const focusable = Array.from(
    dialog.querySelectorAll<HTMLElement>(focusableSelector)
  ).filter((element) => !element.hasAttribute('disabled'));

  if (focusable.length === 0) {
    event.preventDefault();
    return;
  }

  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  const current = document.activeElement;

  if (event.shiftKey && current === first) {
    event.preventDefault();
    last.focus();
    return;
  }

  if (!event.shiftKey && current === last) {
    event.preventDefault();
    first.focus();
  }
}

function galleryVariant(asset: MediaAsset, index: number): string {
  const width = asset.width ?? 0;
  const height = asset.height ?? 0;

  if (width > 0 && height > 0) {
    const ratio = width / height;
    if (ratio >= 1.45) {
      return 'galleryItemWide';
    }
    if (ratio <= 0.78) {
      return 'galleryItemTall';
    }
  }

  return index % 7 === 0 ? 'galleryItemFeatured' : '';
}
