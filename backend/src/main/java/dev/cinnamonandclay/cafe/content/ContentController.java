package dev.cinnamonandclay.cafe.content;

import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

@RestController
@RequestMapping("/api/v1/content")
class ContentController {

    private final ContentService contentService;

    ContentController(ContentService contentService) {
        this.contentService = contentService;
    }

    @GetMapping("/site")
    ResponseEntity<ContentService.SiteContentResponse> getSiteContent() {
        return ResponseEntity.ok()
                .cacheControl(
                        CacheControl.maxAge(Duration.ofMinutes(5))
                                .cachePublic()
                )
                .body(contentService.getPublicSiteContent());
    }
}