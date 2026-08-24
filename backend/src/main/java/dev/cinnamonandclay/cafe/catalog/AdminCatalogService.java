package dev.cinnamonandclay.cafe.catalog;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;
import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class AdminCatalogService {

    private final MenuCategoryRepository categoryRepository;
    private final MenuItemRepository itemRepository;
    private final AuditTrail auditTrail;

    AdminCatalogService(
            MenuCategoryRepository categoryRepository,
            MenuItemRepository itemRepository,
            AuditTrail auditTrail
    ) {
        this.categoryRepository = categoryRepository;
        this.itemRepository = itemRepository;
        this.auditTrail = auditTrail;
    }

    @Transactional(readOnly = true)
    AdminCatalogResponse getCatalog() {
        List<MenuCategoryEntity> categories = categoryRepository
                .findAllByOrderBySortOrderAscNameAsc();

        if (categories.isEmpty()) {
            return new AdminCatalogResponse("LKR", List.of());
        }

        List<UUID> categoryIds = categories.stream()
                .map(MenuCategoryEntity::id)
                .toList();

        Map<UUID, List<MenuItemEntity>> itemsByCategory = itemRepository
                .findByCategoryIdInOrderByCategoryIdAscSortOrderAscNameAsc(categoryIds)
                .stream()
                .collect(Collectors.groupingBy(MenuItemEntity::categoryId));

        return new AdminCatalogResponse(
                "LKR",
                categories.stream()
                        .map(category -> toCategory(
                                category,
                                itemsByCategory.getOrDefault(category.id(), List.of())
                        ))
                        .toList()
        );
    }

    @Transactional
    AdminCategoryResponse createCategory(CreateCategoryCommand command) {
        String slug = normalizeSlug(command.slug());
        String name = normalizeText(command.name());

        if (categoryRepository.existsBySlugIgnoreCase(slug)) {
            throw new ResourceConflictException(
                    "A menu category already uses the slug '" + slug + "'."
            );
        }

        MenuCategoryEntity category = MenuCategoryEntity.create(
                slug,
                name,
                command.sortOrder(),
                command.active()
        );

        category = categoryRepository.saveAndFlush(category);
        AdminCategoryResponse created = toCategory(category, List.of());
        auditTrail.record(
                AuditAction.CREATE,
                "catalog.category",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    AdminCategoryResponse updateCategory(
            UUID categoryId,
            UpdateCategoryCommand command
    ) {
        MenuCategoryEntity category = requireCategory(categoryId);
        assertVersion(category.version(), command.version());

        String slug = normalizeSlug(command.slug());
        String name = normalizeText(command.name());

        if (categoryRepository.existsBySlugIgnoreCaseAndIdNot(slug, categoryId)) {
            throw new ResourceConflictException(
                    "A menu category already uses the slug '" + slug + "'."
            );
        }

        List<MenuItemEntity> beforeItems = itemRepository
                .findByCategoryIdOrderBySortOrderAscNameAsc(categoryId);
        AdminCategoryResponse before = toCategory(category, beforeItems);

        category.update(
                slug,
                name,
                command.sortOrder(),
                command.active()
        );

        MenuCategoryEntity saved = categoryRepository.saveAndFlush(category);
        List<MenuItemEntity> items = itemRepository
                .findByCategoryIdOrderBySortOrderAscNameAsc(categoryId);
        AdminCategoryResponse after = toCategory(saved, items);
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "catalog.category",
                categoryId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateCategory(UUID categoryId, long version) {
        MenuCategoryEntity category = requireCategory(categoryId);
        assertVersion(category.version(), version);
        List<MenuItemEntity> items = itemRepository
                .findByCategoryIdOrderBySortOrderAscNameAsc(categoryId);
        AdminCategoryResponse before = toCategory(category, items);
        category.deactivate();
        MenuCategoryEntity saved = categoryRepository.saveAndFlush(category);
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "catalog.category",
                categoryId,
                before,
                toCategory(saved, items)
        );
    }

    @Transactional
    AdminItemResponse createItem(
            UUID categoryId,
            CreateItemCommand command
    ) {
        requireCategory(categoryId);

        String name = normalizeText(command.name());
        if (itemRepository.existsByCategoryIdAndNameIgnoreCase(categoryId, name)) {
            throw new ResourceConflictException(
                    "This category already contains an item named '" + name + "'."
            );
        }

        MenuItemEntity item = MenuItemEntity.create(
                categoryId,
                name,
                normalizeDescription(command.description()),
                command.priceMinor(),
                normalizeCurrency(command.currency()),
                command.sortOrder(),
                command.active()
        );

        AdminItemResponse created = toItem(itemRepository.saveAndFlush(item));
        auditTrail.record(
                AuditAction.CREATE,
                "catalog.item",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    AdminItemResponse updateItem(
            UUID itemId,
            UpdateItemCommand command
    ) {
        MenuItemEntity item = requireItem(itemId);
        assertVersion(item.version(), command.version());
        requireCategory(command.categoryId());

        String name = normalizeText(command.name());
        if (itemRepository.existsByCategoryIdAndNameIgnoreCaseAndIdNot(
                command.categoryId(),
                name,
                itemId
        )) {
            throw new ResourceConflictException(
                    "The target category already contains an item named '" + name + "'."
            );
        }

        AdminItemResponse before = toItem(item);
        item.update(
                command.categoryId(),
                name,
                normalizeDescription(command.description()),
                command.priceMinor(),
                normalizeCurrency(command.currency()),
                command.sortOrder(),
                command.active()
        );

        AdminItemResponse after = toItem(itemRepository.saveAndFlush(item));
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "catalog.item",
                itemId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateItem(UUID itemId, long version) {
        MenuItemEntity item = requireItem(itemId);
        assertVersion(item.version(), version);
        AdminItemResponse before = toItem(item);
        item.deactivate();
        AdminItemResponse after = toItem(itemRepository.saveAndFlush(item));
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "catalog.item",
                itemId,
                before,
                after
        );
    }

    private MenuCategoryEntity requireCategory(UUID id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Menu category " + id + " was not found."
                ));
    }

    private MenuItemEntity requireItem(UUID id) {
        return itemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Menu item " + id + " was not found."
                ));
    }

    private static void assertVersion(long currentVersion, long suppliedVersion) {
        if (currentVersion != suppliedVersion) {
            throw new ResourceConflictException(
                    "This catalog record changed after it was loaded. Refresh and try again."
            );
        }
    }

    private static AuditAction activeChangeAction(boolean before, boolean after) {
        if (!before && after) {
            return AuditAction.REACTIVATE;
        }
        if (before && !after) {
            return AuditAction.DEACTIVATE;
        }
        return AuditAction.UPDATE;
    }

    private static String normalizeSlug(String value) {
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private static String normalizeText(String value) {
        return value.trim();
    }

    private static String normalizeDescription(String value) {
        return value.trim();
    }

    private static String normalizeCurrency(String value) {
        return value.trim().toUpperCase(Locale.ROOT);
    }

    private static AdminCategoryResponse toCategory(
            MenuCategoryEntity category,
            List<MenuItemEntity> items
    ) {
        return new AdminCategoryResponse(
                category.id(),
                category.slug(),
                category.name(),
                category.sortOrder(),
                category.active(),
                category.version(),
                items.stream().map(AdminCatalogService::toItem).toList()
        );
    }

    private static AdminItemResponse toItem(MenuItemEntity item) {
        return new AdminItemResponse(
                item.id(),
                item.categoryId(),
                item.name(),
                item.description(),
                item.priceMinor(),
                item.currency(),
                item.sortOrder(),
                item.active(),
                item.version()
        );
    }

    record AdminCatalogResponse(
            String defaultCurrency,
            List<AdminCategoryResponse> categories
    ) {
    }

    record AdminCategoryResponse(
            UUID id,
            String slug,
            String name,
            int sortOrder,
            boolean active,
            long version,
            List<AdminItemResponse> items
    ) {
    }

    record AdminItemResponse(
            UUID id,
            UUID categoryId,
            String name,
            String description,
            long priceMinor,
            String currency,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record CreateCategoryCommand(
            String slug,
            String name,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateCategoryCommand(
            String slug,
            String name,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record CreateItemCommand(
            String name,
            String description,
            long priceMinor,
            String currency,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateItemCommand(
            UUID categoryId,
            String name,
            String description,
            long priceMinor,
            String currency,
            int sortOrder,
            boolean active,
            long version
    ) {
    }
}
