import { backendGet } from '@/lib/backend';

export type Money = {
  amountMinor: number;
  currency: string;
};

export type MenuItem = {
  id: string;
  name: string;
  description: string;
  price: Money;
};

export type MenuCategory = {
  id: string;
  slug: string;
  name: string;
  items: MenuItem[];
};

export type MenuResponse = {
  defaultCurrency: string;
  categories: MenuCategory[];
};

export function getMenu(): Promise<MenuResponse> {
  return backendGet<MenuResponse>('/api/v1/catalog/menu', 'catalog');
}

export function formatMoney(money: Money): string {
  if (money.currency.toUpperCase() === 'LKR') {
    return `Rs. ${new Intl.NumberFormat('en-LK', {
      maximumFractionDigits: 0
    }).format(money.amountMinor / 100)}`;
  }

  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: money.currency,
    maximumFractionDigits: 0
  }).format(money.amountMinor / 100);
}