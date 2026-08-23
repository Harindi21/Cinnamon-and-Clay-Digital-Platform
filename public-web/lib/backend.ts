function getBackendBaseUrl(): string {
  const configuredUrl = process.env.BACKEND_INTERNAL_URL?.trim();

  if (configuredUrl) {
    return configuredUrl.replace(/\/+$/, '');
  }

  if (process.env.NODE_ENV === 'development') {
    return 'http://localhost:8080';
  }

  throw new Error(
    'BACKEND_INTERNAL_URL must be configured outside development'
  );
}

export function backendUrl(path: `/${string}`): string {
  return `${getBackendBaseUrl()}${path}`;
}

export async function backendGet<T>(
  path: `/${string}`
): Promise<T> {
  const response = await fetch(
    backendUrl(path),
    {
      next: {
        revalidate: 300
      },
      signal: AbortSignal.timeout(5000)
    }
  );

  if (!response.ok) {
    throw new Error(
      `Backend request ${path} returned HTTP ${response.status}`
    );
  }

  return (await response.json()) as T;
}