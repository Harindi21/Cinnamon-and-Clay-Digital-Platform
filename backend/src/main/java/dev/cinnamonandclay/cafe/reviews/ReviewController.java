package dev.cinnamonandclay.cafe.reviews;

import java.time.Duration;

import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/reviews")
class ReviewController {

    private final ReviewService reviewService;

    ReviewController(
            ReviewService reviewService
    ) {
        this.reviewService = reviewService;
    }

    @GetMapping
    ResponseEntity<ReviewService.PublicReviewsResponse>
    getReviews() {

        return ResponseEntity.ok()
                .cacheControl(
                        CacheControl
                                .maxAge(
                                        Duration.ofMinutes(5)
                                )
                                .cachePublic()
                )
                .body(
                        reviewService.getPublicReviews()
                );
    }
}