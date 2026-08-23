package dev.cinnamonandclay.cafe.contact;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface OpeningHourRepository
        extends JpaRepository<OpeningHourEntity, UUID> {

    List<OpeningHourEntity>
    findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(
            UUID contactProfileId
    );

    List<OpeningHourEntity>
    findByContactProfileIdOrderBySortOrderAscIdAsc(
            UUID contactProfileId
    );
}
