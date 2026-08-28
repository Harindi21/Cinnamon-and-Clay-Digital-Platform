'use client';

import { useEffect, useRef, useState } from 'react';

const links = [
  ['About', '#about'],
  ['Menu', '#menu'],
  ['Gallery', '#gallery'],
  ['Reviews', '#reviews'],
  ['Visit Us', '#visit']
] as const;

export function SiteNav({ brand }: { brand: string }) {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    if (!open) {
      return;
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpen(false);
        toggleRef.current?.focus();
      }
    };

    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [open]);

  useEffect(() => {
    if (!open) {
      return;
    }

    const firstLink = menuRef.current?.querySelector<HTMLAnchorElement>('a');
    firstLink?.focus();
  }, [open]);

  return (
    <nav
      className={`siteNav${scrolled ? ' siteNavScrolled' : ''}${open ? ' siteNavOpen' : ''}`}
      aria-label="Primary"
    >
      <div className="shell siteNavInner">
        <a
          className="siteBrand"
          href="#top"
          onClick={() => setOpen(false)}
        >
          <span aria-hidden="true">☕</span>
          <span>{brand}</span>
        </a>

        <button
          ref={toggleRef}
          className="siteNavToggle"
          type="button"
          aria-expanded={open}
          aria-controls="primary-navigation"
          aria-label={open ? 'Close navigation menu' : 'Open navigation menu'}
          onClick={() => setOpen((value) => !value)}
        >
          <span aria-hidden="true" />
          <span aria-hidden="true" />
          <span aria-hidden="true" />
        </button>

        <div ref={menuRef} className="siteNavMenu" id="primary-navigation">
          {links.map(([label, href]) => (
            <a key={href} href={href} onClick={() => setOpen(false)}>
              {label}
            </a>
          ))}
        </div>
      </div>
    </nav>
  );
}
