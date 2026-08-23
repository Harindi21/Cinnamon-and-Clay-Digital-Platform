package dev.cinnamonandclay.cafe.reviews;

import java.net.URI;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@RestController
@RequestMapping("/api/v1/admin/reviews")
class AdminReviewController {

    private final AdminReviewService service;

    AdminReviewController(AdminReviewService service) {
        this.service = service;
    }

    @GetMapping
    AdminReviewService.AdminReviewsResponse getReviews() {
        return service.getReviews();
    }

    @PostMapping
    ResponseEntity<AdminReviewService.AdminReviewResponse> create(
            @Valid @RequestBody ReviewCreateRequest request
    ) {
        AdminReviewService.AdminReviewResponse created = service.create(
                new AdminReviewService.CreateReviewCommand(
                        request.authorName(),
                        request.body(),
                        request.rating(),
                        request.status(),
                        request.sortOrder()
                )
        );

        return ResponseEntity.created(
                URI.create("/api/v1/admin/reviews/" + created.id())
        ).body(created);
    }

    @PutMapping("/{reviewId}")
    AdminReviewService.AdminReviewResponse update(
            @PathVariable UUID reviewId,
            @Valid @RequestBody ReviewUpdateRequest request
    ) {
        return service.update(
                reviewId,
                new AdminReviewService.UpdateReviewCommand(
                        request.authorName(),
                        request.body(),
                        request.rating(),
                        request.status(),
                        request.sortOrder(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/{reviewId}")
    ResponseEntity<Void> hide(
            @PathVariable UUID reviewId,
            @RequestParam long version
    ) {
        service.hide(reviewId, version);
        return ResponseEntity.noContent().build();
    }

    record ReviewCreateRequest(
            @NotBlank @Size(max = 120) String authorName,
            @NotBlank @Size(max = 1000) String body,
            @Min(1) @Max(5) int rating,
            @NotBlank
            @Pattern(regexp = "^(DRAFT|PUBLISHED|HIDDEN)$", message = "must be DRAFT, PUBLISHED or HIDDEN")
            String status,
            @Min(0) int sortOrder
    ) {
    }

    record ReviewUpdateRequest(
            @NotBlank @Size(max = 120) String authorName,
            @NotBlank @Size(max = 1000) String body,
            @Min(1) @Max(5) int rating,
            @NotBlank
            @Pattern(regexp = "^(DRAFT|PUBLISHED|HIDDEN)$", message = "must be DRAFT, PUBLISHED or HIDDEN")
            String status,
            @Min(0) int sortOrder,
            @Min(0) long version
    ) {
    }
}
