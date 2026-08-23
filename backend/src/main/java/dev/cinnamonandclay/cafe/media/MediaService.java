package dev.cinnamonandclay.cafe.media;

import java.io.InputStream;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class MediaService {

    private final MediaAssetRepository repository;
    private final MediaStorage storage;

    MediaService(
            MediaAssetRepository repository,
            MediaStorage storage
    ) {
        this.repository = repository;
        this.storage = storage;
    }

    @Transactional(readOnly = true)
    PublicMediaResponse getPublicMedia() {
        return new PublicMediaResponse(
                first(MediaPurpose.HERO),
                first(MediaPurpose.ABOUT),
                list(MediaPurpose.GALLERY)
        );
    }

    @Transactional(readOnly = true)
    MediaContent openPublicContent(UUID id) {
        var asset = repository.findById(id)
                .filter(MediaAssetEntity::isActive)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Media asset was not found."
                        )
                );

        return new MediaContent(
                asset.contentType(),
                asset.sizeBytes(),
                asset.checksumSha256(),
                storage.open(asset.objectKey())
        );
    }

    private MediaResponse first(MediaPurpose purpose) {
        return repository
                .findByPurposeAndActiveTrueOrderBySortOrderAscIdAsc(purpose)
                .stream()
                .findFirst()
                .map(this::toResponse)
                .orElse(null);
    }

    private List<MediaResponse> list(MediaPurpose purpose) {
        return repository
                .findByPurposeAndActiveTrueOrderBySortOrderAscIdAsc(purpose)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private MediaResponse toResponse(MediaAssetEntity entity) {
        return new MediaResponse(
                entity.id().toString(),
                "/api/v1/media/" + entity.id() + "/content",
                entity.altText(),
                entity.widthPixels(),
                entity.heightPixels(),
                entity.version()
        );
    }

    record PublicMediaResponse(
            MediaResponse hero,
            MediaResponse about,
            List<MediaResponse> gallery
    ) {
    }

    record MediaResponse(
            String id,
            String url,
            String alt,
            Integer width,
            Integer height,
            long version
    ) {
    }

    record MediaContent(
            String contentType,
            long sizeBytes,
            String checksumSha256,
            InputStream stream
    ) {
    }
}
