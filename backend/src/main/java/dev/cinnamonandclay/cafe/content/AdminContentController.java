package dev.cinnamonandclay.cafe.content;

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
import jakarta.validation.constraints.Size;

@RestController
@RequestMapping("/api/v1/admin/content")
class AdminContentController {

    private final AdminContentService service;

    AdminContentController(AdminContentService service) {
        this.service = service;
    }

    @GetMapping
    AdminContentService.AdminContentResponse getContent() {
        return service.getContent();
    }

    @PutMapping("/site")
    AdminContentService.SiteResponse updateSite(
            @Valid @RequestBody SiteUpdateRequest request
    ) {
        return service.updateSite(new AdminContentService.UpdateSiteCommand(
                request.brandName(),
                request.tagline(),
                request.heroNote(),
                request.menuNote(),
                request.aboutTitle(),
                request.version()
        ));
    }

    @PostMapping("/paragraphs")
    ResponseEntity<AdminContentService.ParagraphResponse> createParagraph(
            @Valid @RequestBody ParagraphCreateRequest request
    ) {
        AdminContentService.ParagraphResponse created = service.createParagraph(
                new AdminContentService.CreateParagraphCommand(
                        request.body(),
                        request.sortOrder(),
                        request.active()
                )
        );
        return ResponseEntity.created(
                URI.create("/api/v1/admin/content/paragraphs/" + created.id())
        ).body(created);
    }

    @PutMapping("/paragraphs/{paragraphId}")
    AdminContentService.ParagraphResponse updateParagraph(
            @PathVariable UUID paragraphId,
            @Valid @RequestBody ParagraphUpdateRequest request
    ) {
        return service.updateParagraph(
                paragraphId,
                new AdminContentService.UpdateParagraphCommand(
                        request.body(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/paragraphs/{paragraphId}")
    ResponseEntity<Void> deactivateParagraph(
            @PathVariable UUID paragraphId,
            @RequestParam long version
    ) {
        service.deactivateParagraph(paragraphId, version);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/features")
    ResponseEntity<AdminContentService.FeatureResponse> createFeature(
            @Valid @RequestBody FeatureCreateRequest request
    ) {
        AdminContentService.FeatureResponse created = service.createFeature(
                new AdminContentService.CreateFeatureCommand(
                        request.icon(),
                        request.title(),
                        request.text(),
                        request.sortOrder(),
                        request.active()
                )
        );
        return ResponseEntity.created(
                URI.create("/api/v1/admin/content/features/" + created.id())
        ).body(created);
    }

    @PutMapping("/features/{featureId}")
    AdminContentService.FeatureResponse updateFeature(
            @PathVariable UUID featureId,
            @Valid @RequestBody FeatureUpdateRequest request
    ) {
        return service.updateFeature(
                featureId,
                new AdminContentService.UpdateFeatureCommand(
                        request.icon(),
                        request.title(),
                        request.text(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/features/{featureId}")
    ResponseEntity<Void> deactivateFeature(
            @PathVariable UUID featureId,
            @RequestParam long version
    ) {
        service.deactivateFeature(featureId, version);
        return ResponseEntity.noContent().build();
    }

    record SiteUpdateRequest(
            @NotBlank @Size(max = 120) String brandName,
            @NotBlank @Size(max = 240) String tagline,
            @NotBlank @Size(max = 300) String heroNote,
            @NotBlank @Size(max = 300) String menuNote,
            @NotBlank @Size(max = 160) String aboutTitle,
            @NotNull @Min(0) Long version
    ) {
    }

    record ParagraphCreateRequest(
            @NotBlank @Size(max = 2000) String body,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record ParagraphUpdateRequest(
            @NotBlank @Size(max = 2000) String body,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }

    record FeatureCreateRequest(
            @NotNull @Size(max = 32) String icon,
            @NotBlank @Size(max = 120) String title,
            @NotBlank @Size(max = 500) String text,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record FeatureUpdateRequest(
            @NotNull @Size(max = 32) String icon,
            @NotBlank @Size(max = 120) String title,
            @NotBlank @Size(max = 500) String text,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }
}
