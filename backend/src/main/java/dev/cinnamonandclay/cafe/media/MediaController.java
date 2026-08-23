package dev.cinnamonandclay.cafe.media;

import java.time.Duration;
import java.util.UUID;

import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

@RestController
@RequestMapping("/api/v1/media")
class MediaController {

    private final MediaService mediaService;

    MediaController(MediaService mediaService) {
        this.mediaService = mediaService;
    }

    @GetMapping
    ResponseEntity<MediaService.PublicMediaResponse> getPublicMedia() {
        return ResponseEntity.ok()
                .cacheControl(
                        CacheControl.maxAge(Duration.ofMinutes(5))
                                .cachePublic()
                )
                .body(mediaService.getPublicMedia());
    }

    @GetMapping("/{id}/content")
    ResponseEntity<StreamingResponseBody> getContent(
            @PathVariable UUID id
    ) {
        var content = mediaService.openPublicContent(id);

        StreamingResponseBody body = outputStream -> {
            try (var inputStream = content.stream()) {
                inputStream.transferTo(outputStream);
            }
        };

        ResponseEntity.BodyBuilder response = ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(content.contentType()))
                .contentLength(content.sizeBytes())
                .cacheControl(
                        CacheControl.maxAge(Duration.ofDays(7))
                                .cachePublic()
                )
                .header("X-Content-Type-Options", "nosniff");

        if (content.checksumSha256() != null
                && !content.checksumSha256().isBlank()) {
            response.eTag('"' + content.checksumSha256() + '"');
        }

        return response.body(body);
    }
}
