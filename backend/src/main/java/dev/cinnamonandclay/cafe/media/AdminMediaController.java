package dev.cinnamonandclay.cafe.media;

import java.net.URI;
import java.util.List;
import java.util.UUID;

import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@RestController
@Validated
@RequestMapping("/api/v1/admin/media")
class AdminMediaController {

    private final AdminMediaService service;

    AdminMediaController(AdminMediaService service) {
        this.service = service;
    }

    @GetMapping
    AdminMediaService.AdminMediaResponse getMedia() {
        return service.listAssets();
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    ResponseEntity<AdminMediaService.AssetResponse> upload(
            @RequestPart("file") MultipartFile file,
            @RequestParam @NotNull MediaPurpose purpose,
            @RequestParam(defaultValue = "") @Size(max = 300) String altText,
            @RequestParam(defaultValue = "") @Size(max = 500) String caption,
            @RequestParam(defaultValue = "50") @Min(0) @Max(100) int focalXPercent,
            @RequestParam(defaultValue = "50") @Min(0) @Max(100) int focalYPercent,
            @RequestParam(defaultValue = "0") @Min(0) @Max(100_000) int sortOrder,
            @RequestParam(defaultValue = "true") boolean active
    ) {
        AdminMediaService.AssetResponse created = service.upload(
                file,
                purpose,
                altText,
                caption,
                focalXPercent,
                focalYPercent,
                sortOrder,
                active
        );
        return ResponseEntity.created(
                URI.create("/api/v1/admin/media/" + created.id())
        ).body(created);
    }

    @PutMapping("/{id}")
    AdminMediaService.AssetResponse updateMetadata(
            @PathVariable UUID id,
            @Valid @RequestBody MetadataUpdateRequest request
    ) {
        return service.updateMetadata(
                id,
                new AdminMediaService.UpdateMetadataCommand(
                        request.purpose(),
                        request.altText(),
                        request.caption(),
                        request.focalXPercent(),
                        request.focalYPercent(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @PutMapping("/gallery/order")
    AdminMediaService.GalleryOrderResponse reorderGallery(
            @Valid @RequestBody GalleryOrderRequest request
    ) {
        return service.reorderGallery(
                request.items().stream()
                        .map(item -> new AdminMediaService.GalleryOrderItem(
                                item.id(),
                                item.version()
                        ))
                        .toList()
        );
    }

    @PutMapping(
            path = "/{id}/content",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    AdminMediaService.AssetResponse replaceContent(
            @PathVariable UUID id,
            @RequestPart("file") MultipartFile file,
            @RequestParam @Min(0) long version
    ) {
        return service.replaceFile(id, version, file);
    }

    @GetMapping("/{id}/content")
    ResponseEntity<StreamingResponseBody> getAdminContent(
            @PathVariable UUID id
    ) {
        AdminMediaService.AdminMediaContent content = service.openContent(id);
        StreamingResponseBody body = outputStream -> {
            try (var inputStream = content.stream()) {
                inputStream.transferTo(outputStream);
            }
        };

        ResponseEntity.BodyBuilder response = ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.contentType()))
                .contentLength(content.sizeBytes())
                .cacheControl(CacheControl.noStore())
                .header("X-Content-Type-Options", "nosniff");
        if (content.checksumSha256() != null
                && !content.checksumSha256().isBlank()) {
            response.eTag('"' + content.checksumSha256() + '"');
        }
        return response.body(body);
    }

    @DeleteMapping("/{id}")
    ResponseEntity<Void> deactivate(
            @PathVariable UUID id,
            @RequestParam @Min(0) long version
    ) {
        service.deactivate(id, version);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/orphans")
    AdminMediaService.OrphanReport getOrphans() {
        return service.findOrphans();
    }

    @DeleteMapping("/orphans")
    AdminMediaService.OrphanCleanupResponse cleanupOrphans() {
        return service.cleanupOrphans();
    }

    record MetadataUpdateRequest(
            @NotNull MediaPurpose purpose,
            @Size(max = 300) String altText,
            @Size(max = 500) String caption,
            @Min(0) @Max(100) Integer focalXPercent,
            @Min(0) @Max(100) Integer focalYPercent,
            @Min(0) @Max(100_000) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }

    record GalleryOrderRequest(
            @NotNull @Size(min = 1, max = 100)
            List<@Valid GalleryOrderItemRequest> items
    ) {
    }

    record GalleryOrderItemRequest(
            @NotNull UUID id,
            @NotNull @Min(0) Long version
    ) {
    }
}
