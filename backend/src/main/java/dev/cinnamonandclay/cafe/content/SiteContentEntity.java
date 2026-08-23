package dev.cinnamonandclay.cafe.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

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

    protected SiteContentEntity() {
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
}