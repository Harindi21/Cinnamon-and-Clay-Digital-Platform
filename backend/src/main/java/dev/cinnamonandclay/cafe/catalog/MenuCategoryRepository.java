package dev.cinnamonandclay.cafe.catalog;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

interface MenuCategoryRepository extends JpaRepository<MenuCategoryEntity, UUID> {
    List<MenuCategoryEntity> findByActiveTrueOrderBySortOrderAscNameAsc();
}
