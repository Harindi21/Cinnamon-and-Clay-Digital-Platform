package dev.cinnamonandclay.cafe.contact;

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
@Table(name = "social_link")
class SocialLinkEntity {

    @Id
    private UUID id;

    @Column(name = "contact_profile_id", nullable = false)
    private UUID contactProfileId;

    @Column(nullable = false, length = 40)
    private String platform;

    @Column(nullable = false, length = 1000)
    private String url;

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

    protected SocialLinkEntity() {
    }

    static SocialLinkEntity create(
            UUID contactProfileId,
            String platform,
            String url,
            int sortOrder,
            boolean active
    ) {
        SocialLinkEntity link = new SocialLinkEntity();
        link.id = UUID.randomUUID();
        link.contactProfileId = contactProfileId;
        link.platform = platform;
        link.url = url;
        link.sortOrder = sortOrder;
        link.active = active;
        link.version = 0;
        return link;
    }

    void update(
            String platform,
            String url,
            int sortOrder,
            boolean active
    ) {
        this.platform = platform;
        this.url = url;
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

    UUID contactProfileId() {
        return contactProfileId;
    }

    String platform() {
        return platform;
    }

    String url() {
        return url;
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
