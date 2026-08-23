package dev.cinnamonandclay.cafe.catalog;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CatalogService {

    private final MenuCategoryRepository categoryRepository;
    private final MenuItemRepository itemRepository;

    CatalogService(MenuCategoryRepository categoryRepository, MenuItemRepository itemRepository) {
        this.categoryRepository = categoryRepository;
        this.itemRepository = itemRepository;
    }

    @Transactional(readOnly = true)
    public MenuResponse getPublicMenu() {
        var categories = categoryRepository.findByActiveTrueOrderBySortOrderAscNameAsc();
        if (categories.isEmpty()) {
            return new MenuResponse("LKR", List.of());
        }

        var categoryIds = categories.stream().map(MenuCategoryEntity::id).toList();
        Map<UUID, List<MenuItemEntity>> itemsByCategory = itemRepository
                .findByCategoryIdInAndActiveTrueOrderBySortOrderAscNameAsc(categoryIds)
                .stream()
                .collect(Collectors.groupingBy(MenuItemEntity::categoryId));

        var categoryResponses = categories.stream()
                .map(category -> new CategoryResponse(
                        category.id(),
                        category.slug(),
                        category.name(),
                        itemsByCategory.getOrDefault(category.id(), List.of()).stream()
                                .map(item -> new ItemResponse(
                                        item.id(),
                                        item.name(),
                                        item.description(),
                                        new MoneyResponse(item.priceMinor(), item.currency())
                                ))
                                .toList()
                ))
                .toList();

        return new MenuResponse("LKR", categoryResponses);
    }

    public record MenuResponse(String defaultCurrency, List<CategoryResponse> categories) {
    }

    public record CategoryResponse(UUID id, String slug, String name, List<ItemResponse> items) {
    }

    public record ItemResponse(UUID id, String name, String description, MoneyResponse price) {
    }

    public record MoneyResponse(long amountMinor, String currency) {
    }
}
