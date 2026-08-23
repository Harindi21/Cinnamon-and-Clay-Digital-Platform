package dev.cinnamonandclay.cafe.contact;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface SocialLinkRepository
        extends JpaRepository<SocialLinkEntity, UUID> {

    List<SocialLinkEntity>
    findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(
            UUID contactProfileId
    );

    List<SocialLinkEntity>
    findByContactProfileIdOrderBySortOrderAscIdAsc(
            UUID contactProfileId
    );

    boolean existsByContactProfileIdAndPlatformIgnoreCase(
            UUID contactProfileId,
            String platform
    );

    boolean existsByContactProfileIdAndPlatformIgnoreCaseAndIdNot(
            UUID contactProfileId,
            String platform,
            UUID id
    );
}
