import { backendUrl } from '@/lib/backend';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type RouteContext = {
  params: Promise<{
    id: string;
  }>;
};

export async function GET(
  _request: Request,
  context: RouteContext
) {
  const { id } = await context.params;

  if (!UUID_PATTERN.test(id)) {
    return new Response(null, {
      status: 404
    });
  }

  try {
    const upstream = await fetch(
      backendUrl(`/api/v1/media/${id}/content`),
      {
        cache: 'no-store',
        signal: AbortSignal.timeout(10_000)
      }
    );

    if (upstream.status === 404) {
      return new Response(null, {
        status: 404
      });
    }

    if (!upstream.ok || !upstream.body) {
      console.error(
        `Media upstream request failed: ${upstream.status}`
      );

      return new Response(null, {
        status: 502
      });
    }

    const headers = new Headers();

    const contentType = upstream.headers.get('content-type');
    const contentLength = upstream.headers.get('content-length');
    const cacheControl = upstream.headers.get('cache-control');
    const etag = upstream.headers.get('etag');

    if (contentType) {
      headers.set('Content-Type', contentType);
    }

    if (contentLength) {
      headers.set('Content-Length', contentLength);
    }

    if (etag) {
      headers.set('ETag', etag);
    }

    headers.set(
      'Cache-Control',
      cacheControl ?? 'public, max-age=604800'
    );

    headers.set(
      'X-Content-Type-Options',
      'nosniff'
    );

    return new Response(upstream.body, {
      status: 200,
      headers
    });
  } catch (error) {
    console.error('Unable to retrieve media from backend.', error);

    return new Response(null, {
      status: 502
    });
  }
}