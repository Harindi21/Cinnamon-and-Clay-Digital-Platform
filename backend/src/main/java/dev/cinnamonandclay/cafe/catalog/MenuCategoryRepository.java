package dev.cinnamonandclay.cafe.catalog;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface MenuCategoryRepository extends JpaRepository<MenuCategoryEntity, UUID> {
    List<MenuCategoryEntity> findByActiveTrueOrderBySortOrderAscNameAsc();

    List<MenuCategoryEntity> findAllByOrderBySortOrderAscNameAsc();

    boolean existsBySlugIgnoreCaseAndIdNot(String slug, UUID id);

    boolean existsBySlugIgnoreCase(String slug);
}
