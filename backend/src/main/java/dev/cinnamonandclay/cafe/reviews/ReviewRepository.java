package dev.cinnamonandclay.cafe.reviews;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface ReviewRepository
        extends JpaRepository<ReviewEntity, UUID> {

    List<ReviewEntity>
    findByStatusOrderBySortOrderAscPublishedAtDesc(
            ReviewStatus status
    );
}