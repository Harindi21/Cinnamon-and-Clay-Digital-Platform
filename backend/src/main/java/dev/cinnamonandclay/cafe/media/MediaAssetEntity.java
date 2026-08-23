package dev.cinnamonandclay.cafe.media;

import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "media_asset")
class MediaAssetEntity {

    @Id
    private UUID id;

    @Column(name = "object_key", nullable = false, unique = true, length = 500)
    private String objectKey;

    @Column(name = "original_filename", nullable = false, length = 255)
    private String originalFilename;

    @Column(name = "content_type", nullable = false, length = 100)
    private String contentType;

    @Column(name = "size_bytes", nullable = false)
    private long sizeBytes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private MediaPurpose purpose;

    @Column(name = "alt_text", nullable = false, length = 300)
    private String altText;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false)
    private boolean active;

    @Version
    @Column(nullable = false)
    private long version;

    protected MediaAssetEntity() {
    }

    UUID id() {
        return id;
    }

    String objectKey() {
        return objectKey;
    }

    String contentType() {
        return contentType;
    }

    long sizeBytes() {
    return sizeBytes;
    }

    String altText() {
        return altText;
    }

    MediaPurpose purpose() {
        return purpose;
    }

    boolean isActive() {
    return active;
}
}