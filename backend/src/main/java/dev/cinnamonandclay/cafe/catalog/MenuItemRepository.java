package dev.cinnamonandclay.cafe.catalog;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

interface MenuItemRepository extends JpaRepository<MenuItemEntity, UUID> {
    List<MenuItemEntity> findByCategoryIdInAndActiveTrueOrderBySortOrderAscNameAsc(Collection<UUID> categoryIds);

    List<MenuItemEntity> findByCategoryIdInOrderByCategoryIdAscSortOrderAscNameAsc(Collection<UUID> categoryIds);

    List<MenuItemEntity> findByCategoryIdOrderBySortOrderAscNameAsc(UUID categoryId);

    boolean existsByCategoryIdAndNameIgnoreCaseAndIdNot(UUID categoryId, String name, UUID id);

    boolean existsByCategoryIdAndNameIgnoreCase(UUID categoryId, String name);
}
