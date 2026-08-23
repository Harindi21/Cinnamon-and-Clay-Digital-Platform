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
@Table(name = "site_content")
class SiteContentEntity {

    @Id
    private UUID id;

    @Column(name = "brand_name", nullable = false, length = 120)
    private String brandName;

    @Column(nullable = false, length = 240)
    private String tagline;

    @Column(name = "hero_note", nullable = false, length = 300)
    private String heroNote;

    @Column(name = "menu_note", nullable = false, length = 300)
    private String menuNote;

    @Column(name = "about_title", nullable = false, length = 160)
    private String aboutTitle;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected SiteContentEntity() {
    }

    void update(
            String brandName,
            String tagline,
            String heroNote,
            String menuNote,
            String aboutTitle
    ) {
        this.brandName = brandName;
        this.tagline = tagline;
        this.heroNote = heroNote;
        this.menuNote = menuNote;
        this.aboutTitle = aboutTitle;
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

    String brandName() {
        return brandName;
    }

    String tagline() {
        return tagline;
    }

    String heroNote() {
        return heroNote;
    }

    String menuNote() {
        return menuNote;
    }

    String aboutTitle() {
        return aboutTitle;
    }

    long version() {
        return version;
    }
}
