import { backendUrl } from '@/lib/backend';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

export async function GET() {
  try {
    const response = await fetch(
      backendUrl('/actuator/health/readiness'),
      {
        cache: 'no-store',
        signal: AbortSignal.timeout(2_000)
      }
    );

    if (!response.ok) {
      return Response.json(
        {
          status: 'DOWN',
          dependencies: {
            backend: `HTTP_${response.status}`
          }
        },
        {
          status: 503,
          headers: noStoreHeaders()
        }
      );
    }

    const body = (await response.json()) as { status?: unknown };
    const backendStatus =
      typeof body.status === 'string' ? body.status : 'UNKNOWN';
    const ready = backendStatus.toUpperCase() === 'UP';

    return Response.json(
      {
        status: ready ? 'UP' : 'DOWN',
        dependencies: {
          backend: backendStatus
        }
      },
      {
        status: ready ? 200 : 503,
        headers: noStoreHeaders()
      }
    );
  } catch {
    return Response.json(
      {
        status: 'DOWN',
        dependencies: {
          backend: 'UNREACHABLE'
        }
      },
      {
        status: 503,
        headers: noStoreHeaders()
      }
    );
  }
}

function noStoreHeaders(): HeadersInit {
  return {
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff'
  };
}
