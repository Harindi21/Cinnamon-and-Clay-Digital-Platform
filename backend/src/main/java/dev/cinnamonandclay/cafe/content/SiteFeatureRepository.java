// SiteFeatureRepository.java
package dev.cinnamonandclay.cafe.content;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface SiteFeatureRepository
        extends JpaRepository<SiteFeatureEntity, UUID> {

    List<SiteFeatureEntity>
    findBySiteContentIdAndActiveTrueOrderBySortOrderAsc(
            UUID siteContentId
    );
}