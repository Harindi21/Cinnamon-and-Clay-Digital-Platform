package dev.cinnamonandclay.cafe.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

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

    protected SiteFeatureEntity() {
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
}