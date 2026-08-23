package dev.cinnamonandclay.cafe.catalog;

import java.net.URI;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@RestController
@RequestMapping("/api/v1/admin/catalog")
class AdminCatalogController {

    private final AdminCatalogService service;

    AdminCatalogController(AdminCatalogService service) {
        this.service = service;
    }

    @GetMapping
    AdminCatalogService.AdminCatalogResponse getCatalog() {
        return service.getCatalog();
    }

    @PostMapping("/categories")
    ResponseEntity<AdminCatalogService.AdminCategoryResponse> createCategory(
            @Valid @RequestBody CategoryCreateRequest request
    ) {
        AdminCatalogService.AdminCategoryResponse created = service.createCategory(
                new AdminCatalogService.CreateCategoryCommand(
                        request.slug(),
                        request.name(),
                        request.sortOrder(),
                        request.active()
                )
        );

        return ResponseEntity.created(
                URI.create("/api/v1/admin/catalog/categories/" + created.id())
        ).body(created);
    }

    @PutMapping("/categories/{categoryId}")
    AdminCatalogService.AdminCategoryResponse updateCategory(
            @PathVariable UUID categoryId,
            @Valid @RequestBody CategoryUpdateRequest request
    ) {
        return service.updateCategory(
                categoryId,
                new AdminCatalogService.UpdateCategoryCommand(
                        request.slug(),
                        request.name(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/categories/{categoryId}")
    ResponseEntity<Void> deactivateCategory(
            @PathVariable UUID categoryId,
            @RequestParam long version
    ) {
        service.deactivateCategory(categoryId, version);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/categories/{categoryId}/items")
    ResponseEntity<AdminCatalogService.AdminItemResponse> createItem(
            @PathVariable UUID categoryId,
            @Valid @RequestBody ItemCreateRequest request
    ) {
        AdminCatalogService.AdminItemResponse created = service.createItem(
                categoryId,
                new AdminCatalogService.CreateItemCommand(
                        request.name(),
                        request.description(),
                        request.priceMinor(),
                        request.currency(),
                        request.sortOrder(),
                        request.active()
                )
        );

        return ResponseEntity.created(
                URI.create("/api/v1/admin/catalog/items/" + created.id())
        ).body(created);
    }

    @PutMapping("/items/{itemId}")
    AdminCatalogService.AdminItemResponse updateItem(
            @PathVariable UUID itemId,
            @Valid @RequestBody ItemUpdateRequest request
    ) {
        return service.updateItem(
                itemId,
                new AdminCatalogService.UpdateItemCommand(
                        request.categoryId(),
                        request.name(),
                        request.description(),
                        request.priceMinor(),
                        request.currency(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/items/{itemId}")
    ResponseEntity<Void> deactivateItem(
            @PathVariable UUID itemId,
            @RequestParam long version
    ) {
        service.deactivateItem(itemId, version);
        return ResponseEntity.noContent().build();
    }

    record CategoryCreateRequest(
            @NotBlank
            @Size(max = 80)
            @Pattern(
                    regexp = "^[a-z0-9]+(?:-[a-z0-9]+)*$",
                    message = "must contain lowercase letters, numbers and single hyphens only"
            )
            String slug,
            @NotBlank @Size(max = 120) String name,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record CategoryUpdateRequest(
            @NotBlank
            @Size(max = 80)
            @Pattern(
                    regexp = "^[a-z0-9]+(?:-[a-z0-9]+)*$",
                    message = "must contain lowercase letters, numbers and single hyphens only"
            )
            String slug,
            @NotBlank @Size(max = 120) String name,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }

    record ItemCreateRequest(
            @NotBlank @Size(max = 160) String name,
            @NotNull @Size(max = 500) String description,
            @Min(0) long priceMinor,
            @NotBlank
            @Pattern(regexp = "^[A-Z]{3}$", message = "must be a three-letter ISO currency code")
            String currency,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record ItemUpdateRequest(
            @NotNull UUID categoryId,
            @NotBlank @Size(max = 160) String name,
            @NotNull @Size(max = 500) String description,
            @Min(0) long priceMinor,
            @NotBlank
            @Pattern(regexp = "^[A-Z]{3}$", message = "must be a three-letter ISO currency code")
            String currency,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }
}
