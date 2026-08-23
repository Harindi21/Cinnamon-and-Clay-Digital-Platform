package dev.cinnamonandclay.cafe.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

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

    protected AboutParagraphEntity() {
    }

    String body() {
        return body;
    }
}