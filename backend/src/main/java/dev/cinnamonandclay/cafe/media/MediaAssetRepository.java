package dev.cinnamonandclay.cafe.media;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface MediaAssetRepository
        extends JpaRepository<MediaAssetEntity, UUID> {

    List<MediaAssetEntity>
    findByPurposeAndActiveTrueOrderBySortOrderAsc(
            MediaPurpose purpose
    );
}