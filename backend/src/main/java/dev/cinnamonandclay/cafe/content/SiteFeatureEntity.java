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
@Table(name = "site_feature")
class SiteFeatureEntity {

    @Id
    private UUID id;

    @Column(name = "site_content_id", nullable = false)
    private UUID siteContentId;

    @Column(nullable = false, length = 32)
    private String icon;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, length = 500)
    private String text;

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

    protected SiteFeatureEntity() {
    }

    static SiteFeatureEntity create(
            UUID siteContentId,
            String icon,
            String title,
            String text,
            int sortOrder,
            boolean active
    ) {
        SiteFeatureEntity feature = new SiteFeatureEntity();
        feature.id = UUID.randomUUID();
        feature.siteContentId = siteContentId;
        feature.icon = icon;
        feature.title = title;
        feature.text = text;
        feature.sortOrder = sortOrder;
        feature.active = active;
        feature.version = 0;
        return feature;
    }

    void update(
            String icon,
            String title,
            String text,
            int sortOrder,
            boolean active
    ) {
        this.icon = icon;
        this.title = title;
        this.text = text;
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

    String icon() {
        return icon;
    }

    String title() {
        return title;
    }

    String text() {
        return text;
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
