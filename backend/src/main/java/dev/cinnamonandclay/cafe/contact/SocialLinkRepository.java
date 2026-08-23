// SocialLinkRepository.java
package dev.cinnamonandclay.cafe.contact;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface SocialLinkRepository
        extends JpaRepository<SocialLinkEntity, UUID> {

    List<SocialLinkEntity>
    findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(
            UUID contactProfileId
    );
}