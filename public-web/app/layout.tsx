import type { Metadata } from 'next';
import { Fraunces, Inter } from 'next/font/google';
import './globals.css';
import { getSiteContent } from '@/lib/site';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap'
});

const fraunces = Fraunces({
  subsets: ['latin'],
  variable: '--font-serif',
  display: 'swap'
});

const fallbackMetadata = {
  name: 'Cinnamon & Clay',
  tagline: 'Slow coffee. Warm bakes. Good company.',
  description: 'A neighbourhood coffee house in the heart of Colombo.'
};

export async function generateMetadata(): Promise<Metadata> {
  try {
    const content = await getSiteContent();
    return {
      title: `${content.brand.name} — ${content.brand.tagline}`,
      description: content.brand.heroNote
    };
  } catch {
    return {
      title: `${fallbackMetadata.name} — ${fallbackMetadata.tagline}`,
      description: fallbackMetadata.description
    };
  }
}

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} ${fraunces.variable}`}>
        {children}
      </body>
    </html>
  );
}
