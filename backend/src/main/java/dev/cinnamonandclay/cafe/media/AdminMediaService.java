package dev.cinnamonandclay.cafe.media;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;

@Service
class AdminMediaService {

    private static final Logger log = LoggerFactory.getLogger(AdminMediaService.class);
    private static final String MANAGED_OBJECT_PREFIX = "media/";

    private final MediaMetadataManager metadataManager;
    private final MediaStorage storage;
    private final MediaFileInspector inspector;
    private final MediaObjectKeyFactory objectKeyFactory;
    private final MediaUploadProperties uploadProperties;
    private final AuditTrail auditTrail;

    AdminMediaService(
            MediaMetadataManager metadataManager,
            MediaStorage storage,
            MediaFileInspector inspector,
            MediaObjectKeyFactory objectKeyFactory,
            MediaUploadProperties uploadProperties,
            AuditTrail auditTrail
    ) {
        this.metadataManager = metadataManager;
        this.storage = storage;
        this.inspector = inspector;
        this.objectKeyFactory = objectKeyFactory;
        this.uploadProperties = uploadProperties;
        this.auditTrail = auditTrail;
    }

    AdminMediaResponse listAssets() {
        return new AdminMediaResponse(metadataManager.listAssets());
    }

    AssetResponse upload(
            MultipartFile multipartFile,
            MediaPurpose purpose,
            String altText,
            String caption,
            int focalXPercent,
            int focalYPercent,
            int sortOrder,
            boolean active
    ) {
        InspectedMediaFile inspected = inspector.inspect(multipartFile);
        String objectKey = objectKeyFactory.create(purpose, inspected.extension());
        StoredMediaFile storedFile = toStoredFile(objectKey, inspected);

        storage.store(
                objectKey,
                new ByteArrayInputStream(inspected.bytes()),
                inspected.sizeBytes(),
                inspected.contentType()
        );

        try {
            return metadataManager.create(
                    storedFile,
                    purpose,
                    normalizeText(altText),
                    normalizeText(caption),
                    focalXPercent,
                    focalYPercent,
                    sortOrder,
                    active
            );
        } catch (RuntimeException exception) {
            safeDelete(objectKey, "rolling back a failed media metadata create");
            throw exception;
        }
    }

    AssetResponse updateMetadata(UUID id, UpdateMetadataCommand command) {
        return metadataManager.updateMetadata(
                id,
                new UpdateMetadataCommand(
                        command.purpose(),
                        normalizeText(command.altText()),
                        command.caption() == null
                                ? null
                                : normalizeText(command.caption()),
                        command.focalXPercent(),
                        command.focalYPercent(),
                        command.sortOrder(),
                        command.active(),
                        command.version()
                )
        );
    }

    GalleryOrderResponse reorderGallery(List<GalleryOrderItem> items) {
        return new GalleryOrderResponse(metadataManager.reorderGallery(items));
    }

    AssetResponse replaceFile(
            UUID id,
            long version,
            MultipartFile multipartFile
    ) {
        InspectedMediaFile inspected = inspector.inspect(multipartFile);
        AssetResponse current = metadataManager.getAsset(id);

        String objectKey = objectKeyFactory.create(
                current.purpose(),
                inspected.extension()
        );
        StoredMediaFile storedFile = toStoredFile(objectKey, inspected);

        storage.store(
                objectKey,
                new ByteArrayInputStream(inspected.bytes()),
                inspected.sizeBytes(),
                inspected.contentType()
        );

        MediaMetadataManager.ReplacementResult replacement;
        try {
            replacement = metadataManager.replaceFile(id, version, storedFile);
        } catch (RuntimeException exception) {
            safeDelete(objectKey, "rolling back a failed media replacement");
            throw exception;
        }

        safeDelete(
                replacement.previousObjectKey(),
                "removing the superseded media object"
        );
        return replacement.asset();
    }

    void deactivate(UUID id, long version) {
        metadataManager.deactivate(id, version);
    }

    AdminMediaContent openContent(UUID id) {
        MediaMetadataManager.ContentDescriptor descriptor =
                metadataManager.contentDescriptor(id);
        return new AdminMediaContent(
                descriptor.contentType(),
                descriptor.sizeBytes(),
                descriptor.checksumSha256(),
                storage.open(descriptor.objectKey())
        );
    }

    OrphanReport findOrphans() {
        Set<String> referenced = new HashSet<>(metadataManager.referencedObjectKeys());
        Instant cutoff = Instant.now().minus(uploadProperties.orphanGracePeriod());

        List<String> orphanKeys = storage.list(MANAGED_OBJECT_PREFIX)
                .stream()
                .filter(object -> object.lastModified() != null)
                .filter(object -> object.lastModified().isBefore(cutoff))
                .map(MediaStorage.StoredObject::key)
                .filter(key -> !referenced.contains(key))
                .sorted()
                .toList();

        return new OrphanReport(
                orphanKeys.size(),
                uploadProperties.orphanGracePeriod().toString(),
                orphanKeys
        );
    }

    OrphanCleanupResponse cleanupOrphans() {
        OrphanReport report = findOrphans();
        int deleted = 0;
        for (String key : report.objectKeys()) {
            try {
                storage.delete(key);
                deleted++;
            } catch (RuntimeException exception) {
                log.warn("Unable to delete orphan media object {}", key, exception);
            }
        }
        OrphanCleanupResponse response = new OrphanCleanupResponse(
                report.count(),
                deleted,
                report.count() - deleted
        );
        auditTrail.record(
                AuditAction.CLEANUP,
                "media.orphan-cleanup",
                null,
                null,
                response
        );
        return response;
    }

    private void safeDelete(String objectKey, String reason) {
        try {
            storage.delete(objectKey);
        } catch (RuntimeException cleanupFailure) {
            log.warn(
                    "Unable to delete media object {} while {}",
                    objectKey,
                    reason,
                    cleanupFailure
            );
        }
    }

    private static String normalizeText(String value) {
        return value == null ? "" : value.trim();
    }

    private static StoredMediaFile toStoredFile(
            String objectKey,
            InspectedMediaFile file
    ) {
        return new StoredMediaFile(
                objectKey,
                file.originalFilename(),
                file.contentType(),
                file.sizeBytes(),
                file.widthPixels(),
                file.heightPixels(),
                file.checksumSha256()
        );
    }

    static AssetResponse toAdminResponse(MediaAssetEntity entity) {
        return new AssetResponse(
                entity.id(),
                entity.originalFilename(),
                entity.contentType(),
                entity.sizeBytes(),
                entity.purpose(),
                entity.altText(),
                entity.caption(),
                entity.focalXPercent(),
                entity.focalYPercent(),
                entity.sortOrder(),
                entity.isActive(),
                entity.widthPixels(),
                entity.heightPixels(),
                entity.checksumSha256(),
                entity.version(),
                entity.createdAt(),
                entity.updatedAt(),
                "/api/v1/admin/media/" + entity.id() + "/content"
        );
    }

    record AdminMediaResponse(List<AssetResponse> assets) {
    }

    record AssetResponse(
            UUID id,
            String originalFilename,
            String contentType,
            long sizeBytes,
            MediaPurpose purpose,
            String altText,
            String caption,
            int focalXPercent,
            int focalYPercent,
            int sortOrder,
            boolean active,
            Integer widthPixels,
            Integer heightPixels,
            String checksumSha256,
            long version,
            Instant createdAt,
            Instant updatedAt,
            String contentUrl
    ) {
    }

    record UpdateMetadataCommand(
            MediaPurpose purpose,
            String altText,
            String caption,
            Integer focalXPercent,
            Integer focalYPercent,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record GalleryOrderItem(UUID id, long version) {
    }

    record GalleryOrderResponse(List<AssetResponse> assets) {
    }

    record OrphanReport(
            int count,
            String gracePeriod,
            List<String> objectKeys
    ) {
    }

    record OrphanCleanupResponse(
            int discovered,
            int deleted,
            int failed
    ) {
    }

    record AdminMediaContent(
            String contentType,
            long sizeBytes,
            String checksumSha256,
            InputStream stream
    ) {
    }
}
