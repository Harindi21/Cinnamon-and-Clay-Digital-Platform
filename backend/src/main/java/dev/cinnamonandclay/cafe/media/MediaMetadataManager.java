package dev.cinnamonandclay.cafe.media;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class MediaMetadataManager {

    private final MediaAssetRepository repository;

    MediaMetadataManager(MediaAssetRepository repository) {
        this.repository = repository;
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
        return AdminMediaService.toAdminResponse(repository.saveAndFlush(asset));
    }

    @Transactional
    AdminMediaService.AssetResponse updateMetadata(
            UUID id,
            AdminMediaService.UpdateMetadataCommand command
    ) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), command.version());

        if (command.active()) {
            deactivateOtherSingletonAssets(command.purpose(), id);
        }

        asset.updateMetadata(
                command.purpose(),
                command.altText(),
                command.sortOrder(),
                command.active()
        );
        return AdminMediaService.toAdminResponse(repository.saveAndFlush(asset));
    }

    @Transactional
    ReplacementResult replaceFile(
            UUID id,
            long version,
            StoredMediaFile file
    ) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), version);
        String previousObjectKey = asset.objectKey();
        asset.replaceFile(file);
        MediaAssetEntity saved = repository.saveAndFlush(asset);
        return new ReplacementResult(
                AdminMediaService.toAdminResponse(saved),
                previousObjectKey
        );
    }

    @Transactional
    void deactivate(UUID id, long version) {
        MediaAssetEntity asset = requireAsset(id);
        assertVersion(asset.version(), version);
        asset.deactivate();
        repository.saveAndFlush(asset);
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
                activeAsset.deactivate();
            }
        }
        if (!activeAssets.isEmpty()) {
            repository.flush();
        }
    }

    private MediaAssetEntity requireAsset(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Media asset " + id + " was not found."
                ));
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
