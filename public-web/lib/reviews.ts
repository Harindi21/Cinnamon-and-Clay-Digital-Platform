import { backendGet } from '@/lib/backend';

export type PublicReview = {
  id: string;
  authorName: string;
  body: string;
  rating: number;
};

export type PublicReviewsResponse = {
  reviews: PublicReview[];
};

export function getPublicReviews():
Promise<PublicReviewsResponse> {
  return backendGet<PublicReviewsResponse>(
    '/api/v1/reviews'
  );
}