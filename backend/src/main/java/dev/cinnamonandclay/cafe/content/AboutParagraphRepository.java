package dev.cinnamonandclay.cafe.content;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface AboutParagraphRepository
        extends JpaRepository<AboutParagraphEntity, UUID> {

    List<AboutParagraphEntity>
    findBySiteContentIdAndActiveTrueOrderBySortOrderAsc(
            UUID siteContentId
    );

    List<AboutParagraphEntity>
    findBySiteContentIdOrderBySortOrderAscIdAsc(
            UUID siteContentId
    );
}
