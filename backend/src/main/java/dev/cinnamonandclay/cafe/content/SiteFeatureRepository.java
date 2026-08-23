package dev.cinnamonandclay.cafe.content;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface SiteFeatureRepository
        extends JpaRepository<SiteFeatureEntity, UUID> {

    List<SiteFeatureEntity>
    findBySiteContentIdAndActiveTrueOrderBySortOrderAsc(
            UUID siteContentId
    );

    List<SiteFeatureEntity>
    findBySiteContentIdOrderBySortOrderAscIdAsc(
            UUID siteContentId
    );
}
