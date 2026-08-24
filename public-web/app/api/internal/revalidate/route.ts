import { timingSafeEqual } from 'node:crypto';
import { revalidateTag } from 'next/cache';

export const runtime = 'nodejs';

type CacheTag = 'catalog' | 'content' | 'contact' | 'media' | 'reviews';

const ALLOWED_TAGS: ReadonlySet<string> = new Set<CacheTag>([
  'catalog',
  'content',
  'contact',
  'media',
  'reviews'
]);

function isCacheTag(value: unknown): value is CacheTag {
  return typeof value === 'string' && ALLOWED_TAGS.has(value);
}

function secretsMatch(supplied: string | null, expected: string): boolean {
  if (!supplied) {
    return false;
  }

  const suppliedBytes = Buffer.from(supplied, 'utf8');
  const expectedBytes = Buffer.from(expected, 'utf8');

  return (
    suppliedBytes.length === expectedBytes.length &&
    timingSafeEqual(suppliedBytes, expectedBytes)
  );
}

export async function POST(request: Request) {
  const expectedSecret = process.env.PUBLIC_REVALIDATION_SECRET?.trim() ?? '';

  if (!expectedSecret) {
    return Response.json(
      { error: 'Cache revalidation is not configured.' },
      { status: 503 }
    );
  }

  if (
    !secretsMatch(
      request.headers.get('x-revalidation-secret'),
      expectedSecret
    )
  ) {
    return Response.json({ error: 'Unauthorized.' }, { status: 401 });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return Response.json(
      { error: 'Request body must be JSON.' },
      { status: 400 }
    );
  }

  const rawTags: unknown[] | null =
    typeof body === 'object' &&
    body !== null &&
    'tags' in body &&
    Array.isArray(body.tags)
      ? body.tags
      : null;

  if (
    !rawTags ||
    rawTags.length === 0 ||
    rawTags.length > ALLOWED_TAGS.size ||
    !rawTags.every(isCacheTag)
  ) {
    return Response.json(
      { error: 'One or more cache tags are invalid.' },
      { status: 400 }
    );
  }

  const tags: CacheTag[] = rawTags;
  const uniqueTags = [...new Set<CacheTag>(tags)];
  uniqueTags.forEach((tag) => revalidateTag(tag, 'max'));

  return Response.json({ revalidated: true, tags: uniqueTags });
}
