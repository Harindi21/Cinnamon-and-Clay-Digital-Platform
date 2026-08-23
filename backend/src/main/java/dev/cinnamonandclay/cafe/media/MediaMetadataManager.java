package dev.cinnamonandclay.cafe.media;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;
import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class MediaMetadataManager {

    private final MediaAssetRepository repository;
    private final AuditTrail auditTrail;

    MediaMetadataManager(
            MediaAssetRepository repository,
            AuditTrail auditTrail
    ) {
        this.repository = repository;
        this.auditTrail = auditTrail;
    }

    @Transactional(readOnly = true)
    List<AdminMediaService.AssetResponse> listAssets() {
        return repository.findAllByOrderByPurposeAscSortOrderAscIdAsc()
                .stream()
                .map(AdminMediaService::toAdminResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    AdminMediaService.AssetResponse getAsset(UUID id) {
        return AdminMediaService.toAdminResponse(requireAsset(id));
    }

    @Transactional(readOnly = true)
    ContentDescriptor contentDescriptor(UUID id) {
        MediaAssetEntity asset = requireAsset(id);
        return new ContentDescriptor(
                asset.objectKey(),
                asset.contentType(),
                asset.sizeBytes(),
                asset.checksumSha256()
        );
    }

    @Transactional(readOnly = true)
    List<String> referencedObjectKeys() {
        return repository.findAll()
                .stream()
                .map(MediaAssetEntity::objectKey)
                .toList();
    }

    @Transactional
    AdminMediaService.AssetResponse create(
            StoredMediaFile file,
            MediaPurpose purpose,
            String altText,
            int sortOrder,
            boolean active
    ) {
        if (active) {
            deactivateOtherSingletonAssets(purpose, null);
        }

        MediaAssetEntity asset = MediaAssetEntity.create(
                file,
                purpose,
                altText,
                sortOrder,
                active
        );
        AdminMediaService.AssetResponse created = AdminMediaService.toAdminResponse(
                repository.saveAndFlush(asset)
        );
        auditTrail.record(
                AuditAction.CREATE,
                "media.asset",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    AdminMediaService.AssetResponse updateMetadata(
            UUID id,
            AdminMediaService.UpdateMetadataCommand command
    ) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), command.version());
        AdminMediaService.AssetResponse before = AdminMediaService.toAdminResponse(asset);

        if (command.active()) {
            deactivateOtherSingletonAssets(command.purpose(), id);
        }

        asset.updateMetadata(
                command.purpose(),
                command.altText(),
                command.sortOrder(),
                command.active()
        );
        AdminMediaService.AssetResponse after = AdminMediaService.toAdminResponse(
                repository.saveAndFlush(asset)
        );
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "media.asset",
                id,
                before,
                after
        );
        return after;
    }

    @Transactional
    ReplacementResult replaceFile(
            UUID id,
            long version,
            StoredMediaFile file
    ) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), version);
        AdminMediaService.AssetResponse before = AdminMediaService.toAdminResponse(asset);
        String previousObjectKey = asset.objectKey();
        asset.replaceFile(file);
        MediaAssetEntity saved = repository.saveAndFlush(asset);
        AdminMediaService.AssetResponse after = AdminMediaService.toAdminResponse(saved);
        auditTrail.record(
                AuditAction.REPLACE,
                "media.asset",
                id,
                before,
                after,
                Map.of("binaryChanged", true)
        );
        return new ReplacementResult(after, previousObjectKey);
    }

    @Transactional
    void deactivate(UUID id, long version) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), version);
        AdminMediaService.AssetResponse before = AdminMediaService.toAdminResponse(asset);
        asset.deactivate();
        AdminMediaService.AssetResponse after = AdminMediaService.toAdminResponse(
                repository.saveAndFlush(asset)
        );
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "media.asset",
                id,
                before,
                after
        );
    }

    private void deactivateOtherSingletonAssets(
            MediaPurpose purpose,
            UUID assetToKeep
    ) {
        if (!purpose.isSingleton()) {
            return;
        }

        List<MediaAssetEntity> activeAssets = repository
                .findByPurposeAndActiveTrueOrderBySortOrderAscIdAsc(purpose);
        for (MediaAssetEntity activeAsset : activeAssets) {
            if (assetToKeep == null || !activeAsset.id().equals(assetToKeep)) {
                AdminMediaService.AssetResponse before =
                        AdminMediaService.toAdminResponse(activeAsset);
                activeAsset.deactivate();
                repository.flush();
                auditTrail.record(
                        AuditAction.DEACTIVATE,
                        "media.asset",
                        activeAsset.id(),
                        before,
                        AdminMediaService.toAdminResponse(activeAsset),
                        Map.of(
                                "reason", "singleton-purpose-invariant",
                                "purpose", purpose.name()
                        )
                );
            }
        }
    }

    private MediaAssetEntity requireAsset(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Media asset " + id + " was not found."
                ));
    }

    private static AuditAction activeChangeAction(boolean before, boolean after) {
        if (!before && after) {
            return AuditAction.REACTIVATE;
        }
        if (before && !after) {
            return AuditAction.DEACTIVATE;
        }
        return AuditAction.UPDATE;
    }

    private static void assertVersion(long current, long supplied) {
        if (current != supplied) {
            throw new ResourceConflictException(
                    "This media asset changed after it was loaded. Refresh and try again."
            );
        }
    }

    record ReplacementResult(
            AdminMediaService.AssetResponse asset,
            String previousObjectKey
    ) {
    }

    record ContentDescriptor(
            String objectKey,
            String contentType,
            long sizeBytes,
            String checksumSha256
    ) {
    }
}
