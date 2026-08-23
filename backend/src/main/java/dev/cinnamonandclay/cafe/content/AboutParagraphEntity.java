package dev.cinnamonandclay.cafe.content;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "site_about_paragraph")
class AboutParagraphEntity {

    @Id
    private UUID id;

    @Column(name = "site_content_id", nullable = false)
    private UUID siteContentId;

    @Column(nullable = false, length = 2000)
    private String body;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false)
    private boolean active;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected AboutParagraphEntity() {
    }

    static AboutParagraphEntity create(
            UUID siteContentId,
            String body,
            int sortOrder,
            boolean active
    ) {
        AboutParagraphEntity paragraph = new AboutParagraphEntity();
        paragraph.id = UUID.randomUUID();
        paragraph.siteContentId = siteContentId;
        paragraph.body = body;
        paragraph.sortOrder = sortOrder;
        paragraph.active = active;
        paragraph.version = 0;
        return paragraph;
    }

    void update(String body, int sortOrder, boolean active) {
        this.body = body;
        this.sortOrder = sortOrder;
        this.active = active;
    }

    void deactivate() {
        active = false;
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

    UUID siteContentId() {
        return siteContentId;
    }

    String body() {
        return body;
    }

    int sortOrder() {
        return sortOrder;
    }

    boolean active() {
        return active;
    }

    long version() {
        return version;
    }
}
