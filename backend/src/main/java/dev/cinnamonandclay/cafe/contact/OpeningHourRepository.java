// OpeningHourRepository.java
package dev.cinnamonandclay.cafe.contact;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface OpeningHourRepository
        extends JpaRepository<OpeningHourEntity, UUID> {

    List<OpeningHourEntity>
    findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(
            UUID contactProfileId
    );
}