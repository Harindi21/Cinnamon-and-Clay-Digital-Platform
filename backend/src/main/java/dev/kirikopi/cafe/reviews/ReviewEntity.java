package dev.kirikopi.cafe.reviews;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "review")
class ReviewEntity {

    @Id
    private UUID id;

    @Column(
            name = "author_name",
            nullable = false,
            length = 120
    )
    private String authorName;

    @Column(
            nullable = false,
            length = 1000
    )
    private String body;

    @Column(nullable = false)
    private int rating;

    @Enumerated(EnumType.STRING)
    @Column(
            nullable = false,
            length = 20
    )
    private ReviewStatus status;

    @Column(
            name = "sort_order",
            nullable = false
    )
    private int sortOrder;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Version
    @Column(nullable = false)
    private long version;

    protected ReviewEntity() {
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

    int rating() {
        return rating;
    }
}