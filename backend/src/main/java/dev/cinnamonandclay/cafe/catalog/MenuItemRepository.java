package dev.cinnamonandclay.cafe.catalog;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

interface MenuItemRepository extends JpaRepository<MenuItemEntity, UUID> {
    List<MenuItemEntity> findByCategoryIdInAndActiveTrueOrderBySortOrderAscNameAsc(Collection<UUID> categoryIds);
}
