package dev.cinnamonandclay.cafe.reviews;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class ReviewService {

    private final ReviewRepository repository;

    ReviewService(
            ReviewRepository repository
    ) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    PublicReviewsResponse getPublicReviews() {
        List<ReviewResponse> reviews = repository
                .findByStatusOrderBySortOrderAscPublishedAtDesc(
                        ReviewStatus.PUBLISHED
                )
                .stream()
                .map(review ->
                        new ReviewResponse(
                                review.id(),
                                review.authorName(),
                                review.body(),
                                review.rating()
                        )
                )
                .toList();

        return new PublicReviewsResponse(reviews);
    }

    record PublicReviewsResponse(
            List<ReviewResponse> reviews
    ) {
    }

    record ReviewResponse(
            UUID id,
            String authorName,
            String body,
            int rating
    ) {
    }
}