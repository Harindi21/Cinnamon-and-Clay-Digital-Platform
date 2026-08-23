package dev.cinnamonandclay.cafe.content;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
class ContentService {

    private static final UUID SITE_ID =
            UUID.fromString("30000000-0000-0000-0000-000000000001");

    private final SiteContentRepository siteRepository;
    private final AboutParagraphRepository paragraphRepository;
    private final SiteFeatureRepository featureRepository;

    ContentService(
            SiteContentRepository siteRepository,
            AboutParagraphRepository paragraphRepository,
            SiteFeatureRepository featureRepository
    ) {
        this.siteRepository = siteRepository;
        this.paragraphRepository = paragraphRepository;
        this.featureRepository = featureRepository;
    }

    @Transactional(readOnly = true)
    SiteContentResponse getPublicSiteContent() {
        var site = siteRepository.findById(SITE_ID)
                .orElseThrow(() ->
                        new IllegalStateException("Public site content is missing")
                );

        List<String> paragraphs = paragraphRepository
                .findBySiteContentIdAndActiveTrueOrderBySortOrderAsc(SITE_ID)
                .stream()
                .map(AboutParagraphEntity::body)
                .toList();

        List<FeatureResponse> features = featureRepository
                .findBySiteContentIdAndActiveTrueOrderBySortOrderAsc(SITE_ID)
                .stream()
                .map(feature -> new FeatureResponse(
                        feature.icon(),
                        feature.title(),
                        feature.text()
                ))
                .toList();

        return new SiteContentResponse(
                new BrandResponse(
                        site.brandName(),
                        site.tagline(),
                        site.heroNote()
                ),
                site.menuNote(),
                new AboutResponse(
                        site.aboutTitle(),
                        paragraphs,
                        features
                )
        );
    }

    record SiteContentResponse(
            BrandResponse brand,
            String menuNote,
            AboutResponse about
    ) {
    }

    record BrandResponse(
            String name,
            String tagline,
            String heroNote
    ) {
    }

    record AboutResponse(
            String title,
            List<String> paragraphs,
            List<FeatureResponse> features
    ) {
    }

    record FeatureResponse(
            String icon,
            String title,
            String text
    ) {
    }
}