export type BackendCacheTag =
  | 'catalog'
  | 'content'
  | 'contact'
  | 'media'
  | 'reviews';

function getBackendBaseUrl(): string {
  const configuredUrl = process.env.BACKEND_INTERNAL_URL?.trim();

  if (configuredUrl) {
    return configuredUrl.replace(/\/+$/, '');
  }

  if (process.env.NODE_ENV === 'development') {
    return 'http://127.0.0.1:8082';
  }

  throw new Error(
    'BACKEND_INTERNAL_URL must be configured outside development'
  );
}

export function backendUrl(path: `/${string}`): string {
  return `${getBackendBaseUrl()}${path}`;
}

export async function backendGet<T>(
  path: `/${string}`,
  cacheTag: BackendCacheTag
): Promise<T> {
  let response: Response;

  try {
    response = await fetch(
      backendUrl(path),
      {
        next: {
          revalidate: 300,
          tags: [cacheTag]
        },
        signal: AbortSignal.timeout(5000)
      }
    );
  } catch (error) {
    const errorName =
      error instanceof Error ? error.name : 'UnknownError';
    const errorMessage =
      error instanceof Error ? error.message : String(error);

    console.error('Backend request failed before a response', {
      path,
      errorName,
      errorMessage
    });

    // Convert timeout DOMExceptions into a plain Error. This keeps the
    // App Router error boundary stable across Node/Turbopack versions.
    throw new Error(
      `Backend request ${path} failed before a response was received`
    );
  }

  if (!response.ok) {
    const requestId = response.headers.get('x-request-id');

    console.error('Backend request returned an error', {
      path,
      status: response.status,
      requestId
    });

    throw new Error(
      `Backend request ${path} returned HTTP ${response.status}` +
        (requestId ? ` (request ${requestId})` : '')
    );
  }

  return (await response.json()) as T;
}
