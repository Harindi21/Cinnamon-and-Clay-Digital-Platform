import { backendGet } from '@/lib/backend';

export type SiteContent = {
  brand: {
    name: string;
    tagline: string;
    heroNote: string;
  };
  menuNote: string;
  about: {
    title: string;
    paragraphs: string[];
    features: {
      icon: string;
      title: string;
      text: string;
    }[];
  };
};

export type Contact = {
  address: string;
  phone: string;
  email: string;
  mapEmbedUrl: string;
  hours: {
    day: string;
    time: string;
  }[];
  whatsapp: {
    enabled: boolean;
    number: string | null;
    prefill: string;
  };
  socialLinks: {
    platform: string;
    url: string;
  }[];
};

export function getSiteContent(): Promise<SiteContent> {
  return backendGet<SiteContent>('/api/v1/content/site', 'content');
}

export function getContact(): Promise<Contact> {
  return backendGet<Contact>('/api/v1/contact', 'contact');
}

export function whatsappHref(
  whatsapp: Contact['whatsapp']
): string | null {
  if (!whatsapp.enabled || !whatsapp.number) {
    return null;
  }

  const number = whatsapp.number.replace(/\D/g, '');

  if (!number) {
    return null;
  }

  return `https://wa.me/${number}?text=${encodeURIComponent(
    whatsapp.prefill
  )}`;
}