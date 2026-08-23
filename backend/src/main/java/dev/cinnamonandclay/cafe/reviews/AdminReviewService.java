package dev.cinnamonandclay.cafe.reviews;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;
import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class AdminReviewService {

    private final ReviewRepository repository;
    private final AuditTrail auditTrail;

    AdminReviewService(
            ReviewRepository repository,
            AuditTrail auditTrail
    ) {
        this.repository = repository;
        this.auditTrail = auditTrail;
    }

    @Transactional(readOnly = true)
    AdminReviewsResponse getReviews() {
        return new AdminReviewsResponse(
                repository.findAllByOrderBySortOrderAscAuthorNameAsc()
                        .stream()
                        .map(AdminReviewService::toResponse)
                        .toList()
        );
    }

    @Transactional
    AdminReviewResponse create(CreateReviewCommand command) {
        ReviewEntity review = ReviewEntity.create(
                command.authorName().trim(),
                command.body().trim(),
                (short) command.rating(),
                parseStatus(command.status()),
                command.sortOrder()
        );
        AdminReviewResponse created = toResponse(repository.saveAndFlush(review));
        auditTrail.record(
                created.status().equals(ReviewStatus.PUBLISHED.name())
                        ? AuditAction.PUBLISH
                        : AuditAction.CREATE,
                "reviews.review",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    AdminReviewResponse update(UUID id, UpdateReviewCommand command) {
        ReviewEntity review = requireReview(id);
        assertVersion(review.version(), command.version());
        AdminReviewResponse before = toResponse(review);
        review.update(
                command.authorName().trim(),
                command.body().trim(),
                (short) command.rating(),
                parseStatus(command.status()),
                command.sortOrder()
        );
        AdminReviewResponse after = toResponse(repository.saveAndFlush(review));
        auditTrail.record(
                statusChangeAction(before.status(), after.status()),
                "reviews.review",
                id,
                before,
                after
        );
        return after;
    }

    @Transactional
    void hide(UUID id, long version) {
        ReviewEntity review = requireReview(id);
        assertVersion(review.version(), version);
        AdminReviewResponse before = toResponse(review);
        review.changeStatus(ReviewStatus.HIDDEN);
        AdminReviewResponse after = toResponse(repository.saveAndFlush(review));
        auditTrail.record(
                AuditAction.HIDE,
                "reviews.review",
                id,
                before,
                after
        );
    }

    private ReviewEntity requireReview(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Review " + id + " was not found."
                ));
    }

    private static AuditAction statusChangeAction(String before, String after) {
        if (!ReviewStatus.PUBLISHED.name().equals(before)
                && ReviewStatus.PUBLISHED.name().equals(after)) {
            return AuditAction.PUBLISH;
        }
        if (!ReviewStatus.HIDDEN.name().equals(before)
                && ReviewStatus.HIDDEN.name().equals(after)) {
            return AuditAction.HIDE;
        }
        if (ReviewStatus.HIDDEN.name().equals(before)
                && !ReviewStatus.HIDDEN.name().equals(after)) {
            return AuditAction.REACTIVATE;
        }
        return AuditAction.UPDATE;
    }

    private static ReviewStatus parseStatus(String value) {
        return ReviewStatus.valueOf(value.trim().toUpperCase(Locale.ROOT));
    }

    private static void assertVersion(long currentVersion, long suppliedVersion) {
        if (currentVersion != suppliedVersion) {
            throw new ResourceConflictException(
                    "This review changed after it was loaded. Refresh and try again."
            );
        }
    }

    private static AdminReviewResponse toResponse(ReviewEntity review) {
        return new AdminReviewResponse(
                review.id(),
                review.authorName(),
                review.body(),
                review.rating(),
                review.status().name(),
                review.sortOrder(),
                review.publishedAt(),
                review.version()
        );
    }

    record AdminReviewsResponse(List<AdminReviewResponse> reviews) {
    }

    record AdminReviewResponse(
            UUID id,
            String authorName,
            String body,
            int rating,
            String status,
            int sortOrder,
            Instant publishedAt,
            long version
    ) {
    }

    record CreateReviewCommand(
            String authorName,
            String body,
            int rating,
            String status,
            int sortOrder
    ) {
    }

    record UpdateReviewCommand(
            String authorName,
            String body,
            int rating,
            String status,
            int sortOrder,
            long version
    ) {
    }
}
