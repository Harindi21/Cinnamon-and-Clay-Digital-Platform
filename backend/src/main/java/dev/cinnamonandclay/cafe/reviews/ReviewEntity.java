package dev.cinnamonandclay.cafe.reviews;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "review")
class ReviewEntity {

    @Id
    private UUID id;

    @Column(name = "author_name", nullable = false, length = 120)
    private String authorName;

    @Column(nullable = false, length = 1000)
    private String body;

    @Column(nullable = false)
    private short rating;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReviewStatus status;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ReviewEntity() {
    }

    static ReviewEntity create(
            String authorName,
            String body,
            short rating,
            ReviewStatus status,
            int sortOrder
    ) {
        ReviewEntity review = new ReviewEntity();
        review.id = UUID.randomUUID();
        review.authorName = authorName;
        review.body = body;
        review.rating = rating;
        review.status = status;
        review.sortOrder = sortOrder;
        review.version = 0;
        if (status == ReviewStatus.PUBLISHED) {
            review.publishedAt = Instant.now();
        }
        return review;
    }

    void update(
            String authorName,
            String body,
            short rating,
            ReviewStatus status,
            int sortOrder
    ) {
        this.authorName = authorName;
        this.body = body;
        this.rating = rating;
        this.sortOrder = sortOrder;
        changeStatus(status);
    }

    void changeStatus(ReviewStatus status) {
        this.status = status;
        if (status == ReviewStatus.PUBLISHED && publishedAt == null) {
            publishedAt = Instant.now();
        }
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    UUID id() {
        return id;
    }

    String authorName() {
        return authorName;
    }

    String body() {
        return body;
    }

    short rating() {
        return rating;
    }

    ReviewStatus status() {
        return status;
    }

    int sortOrder() {
        return sortOrder;
    }

    Instant publishedAt() {
        return publishedAt;
    }

    long version() {
        return version;
    }
}
