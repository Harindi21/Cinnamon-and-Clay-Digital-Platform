package dev.cinnamonandclay.cafe.media;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface MediaAssetRepository extends JpaRepository<MediaAssetEntity, UUID> {

    List<MediaAssetEntity> findByPurposeAndActiveTrueOrderBySortOrderAscIdAsc(
            MediaPurpose purpose
    );

    List<MediaAssetEntity> findAllByOrderByPurposeAscSortOrderAscIdAsc();
}
