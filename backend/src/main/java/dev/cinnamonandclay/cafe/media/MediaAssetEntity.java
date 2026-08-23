package dev.cinnamonandclay.cafe.media;

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

    @Column(name = "width_pixels")
    private Integer widthPixels;

    @Column(name = "height_pixels")
    private Integer heightPixels;

    @Column(name = "checksum_sha256", length = 64)
    private String checksumSha256;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected MediaAssetEntity() {
    }

    static MediaAssetEntity create(
            StoredMediaFile file,
            MediaPurpose purpose,
            String altText,
            int sortOrder,
            boolean active
    ) {
        MediaAssetEntity asset = new MediaAssetEntity();
        asset.id = UUID.randomUUID();
        asset.applyFile(file);
        asset.purpose = purpose;
        asset.altText = altText;
        asset.sortOrder = sortOrder;
        asset.active = active;
        asset.version = 0;
        return asset;
    }

    void updateMetadata(
            MediaPurpose purpose,
            String altText,
            int sortOrder,
            boolean active
    ) {
        this.purpose = purpose;
        this.altText = altText;
        this.sortOrder = sortOrder;
        this.active = active;
    }

    void replaceFile(StoredMediaFile file) {
        applyFile(file);
    }

    void deactivate() {
        active = false;
    }

    private void applyFile(StoredMediaFile file) {
        objectKey = file.objectKey();
        originalFilename = file.originalFilename();
        contentType = file.contentType();
        sizeBytes = file.sizeBytes();
        widthPixels = file.widthPixels();
        heightPixels = file.heightPixels();
        checksumSha256 = file.checksumSha256();
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

    String objectKey() {
        return objectKey;
    }

    String originalFilename() {
        return originalFilename;
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

    int sortOrder() {
        return sortOrder;
    }

    boolean isActive() {
        return active;
    }

    Integer widthPixels() {
        return widthPixels;
    }

    Integer heightPixels() {
        return heightPixels;
    }

    String checksumSha256() {
        return checksumSha256;
    }

    long version() {
        return version;
    }

    Instant createdAt() {
        return createdAt;
    }

    Instant updatedAt() {
        return updatedAt;
    }
}
