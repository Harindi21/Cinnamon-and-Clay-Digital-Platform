package dev.cinnamonandclay.cafe.content;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;
import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class AdminContentService {

    private static final UUID SITE_ID =
            UUID.fromString("30000000-0000-0000-0000-000000000001");

    private final SiteContentRepository siteRepository;
    private final AboutParagraphRepository paragraphRepository;
    private final SiteFeatureRepository featureRepository;
    private final AuditTrail auditTrail;

    AdminContentService(
            SiteContentRepository siteRepository,
            AboutParagraphRepository paragraphRepository,
            SiteFeatureRepository featureRepository,
            AuditTrail auditTrail
    ) {
        this.siteRepository = siteRepository;
        this.paragraphRepository = paragraphRepository;
        this.featureRepository = featureRepository;
        this.auditTrail = auditTrail;
    }

    @Transactional(readOnly = true)
    AdminContentResponse getContent() {
        return response(requireSite());
    }

    @Transactional
    SiteResponse updateSite(UpdateSiteCommand command) {
        SiteContentEntity site = requireSite();
        assertVersion(site.version(), command.version(), "site content");
        SiteResponse before = toSite(site);
        site.update(
                normalize(command.brandName()),
                normalize(command.tagline()),
                normalize(command.heroNote()),
                normalize(command.menuNote()),
                normalize(command.aboutTitle())
        );
        SiteResponse after = toSite(siteRepository.saveAndFlush(site));
        auditTrail.record(
                AuditAction.UPDATE,
                "content.site",
                SITE_ID,
                before,
                after
        );
        return after;
    }

    @Transactional
    ParagraphResponse createParagraph(CreateParagraphCommand command) {
        requireSite();
        AboutParagraphEntity paragraph = AboutParagraphEntity.create(
                SITE_ID,
                normalize(command.body()),
                command.sortOrder(),
                command.active()
        );
        ParagraphResponse created = toParagraph(paragraphRepository.saveAndFlush(paragraph));
        auditTrail.record(
                AuditAction.CREATE,
                "content.about-paragraph",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    ParagraphResponse updateParagraph(
            UUID paragraphId,
            UpdateParagraphCommand command
    ) {
        AboutParagraphEntity paragraph = requireParagraph(paragraphId);
        assertVersion(paragraph.version(), command.version(), "about paragraph");
        ParagraphResponse before = toParagraph(paragraph);
        paragraph.update(
                normalize(command.body()),
                command.sortOrder(),
                command.active()
        );
        ParagraphResponse after = toParagraph(paragraphRepository.saveAndFlush(paragraph));
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "content.about-paragraph",
                paragraphId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateParagraph(UUID paragraphId, long version) {
        AboutParagraphEntity paragraph = requireParagraph(paragraphId);
        assertVersion(paragraph.version(), version, "about paragraph");
        ParagraphResponse before = toParagraph(paragraph);
        paragraph.deactivate();
        ParagraphResponse after = toParagraph(paragraphRepository.saveAndFlush(paragraph));
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "content.about-paragraph",
                paragraphId,
                before,
                after
        );
    }

    @Transactional
    FeatureResponse createFeature(CreateFeatureCommand command) {
        requireSite();
        SiteFeatureEntity feature = SiteFeatureEntity.create(
                SITE_ID,
                command.icon().trim(),
                normalize(command.title()),
                normalize(command.text()),
                command.sortOrder(),
                command.active()
        );
        FeatureResponse created = toFeature(featureRepository.saveAndFlush(feature));
        auditTrail.record(
                AuditAction.CREATE,
                "content.feature",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    FeatureResponse updateFeature(
            UUID featureId,
            UpdateFeatureCommand command
    ) {
        SiteFeatureEntity feature = requireFeature(featureId);
        assertVersion(feature.version(), command.version(), "site feature");
        FeatureResponse before = toFeature(feature);
        feature.update(
                command.icon().trim(),
                normalize(command.title()),
                normalize(command.text()),
                command.sortOrder(),
                command.active()
        );
        FeatureResponse after = toFeature(featureRepository.saveAndFlush(feature));
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "content.feature",
                featureId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateFeature(UUID featureId, long version) {
        SiteFeatureEntity feature = requireFeature(featureId);
        assertVersion(feature.version(), version, "site feature");
        FeatureResponse before = toFeature(feature);
        feature.deactivate();
        FeatureResponse after = toFeature(featureRepository.saveAndFlush(feature));
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "content.feature",
                featureId,
                before,
                after
        );
    }

    private AdminContentResponse response(SiteContentEntity site) {
        List<ParagraphResponse> paragraphs = paragraphRepository
                .findBySiteContentIdOrderBySortOrderAscIdAsc(SITE_ID)
                .stream()
                .map(AdminContentService::toParagraph)
                .toList();
        List<FeatureResponse> features = featureRepository
                .findBySiteContentIdOrderBySortOrderAscIdAsc(SITE_ID)
                .stream()
                .map(AdminContentService::toFeature)
                .toList();
        return new AdminContentResponse(toSite(site), paragraphs, features);
    }

    private SiteContentEntity requireSite() {
        return siteRepository.findById(SITE_ID)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Site content is not configured."
                ));
    }

    private AboutParagraphEntity requireParagraph(UUID id) {
        return paragraphRepository.findById(id)
                .filter(paragraph -> SITE_ID.equals(paragraph.siteContentId()))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "About paragraph " + id + " was not found."
                ));
    }

    private SiteFeatureEntity requireFeature(UUID id) {
        return featureRepository.findById(id)
                .filter(feature -> SITE_ID.equals(feature.siteContentId()))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Site feature " + id + " was not found."
                ));
    }

    private static void assertVersion(
            long current,
            long supplied,
            String resourceName
    ) {
        if (current != supplied) {
            throw new ResourceConflictException(
                    "This " + resourceName
                            + " changed after it was loaded. Refresh and try again."
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

    private static String normalize(String value) {
        return value.trim();
    }

    private static SiteResponse toSite(SiteContentEntity site) {
        return new SiteResponse(
                site.id(),
                site.brandName(),
                site.tagline(),
                site.heroNote(),
                site.menuNote(),
                site.aboutTitle(),
                site.version()
        );
    }

    private static ParagraphResponse toParagraph(AboutParagraphEntity paragraph) {
        return new ParagraphResponse(
                paragraph.id(),
                paragraph.body(),
                paragraph.sortOrder(),
                paragraph.active(),
                paragraph.version()
        );
    }

    private static FeatureResponse toFeature(SiteFeatureEntity feature) {
        return new FeatureResponse(
                feature.id(),
                feature.icon(),
                feature.title(),
                feature.text(),
                feature.sortOrder(),
                feature.active(),
                feature.version()
        );
    }

    record AdminContentResponse(
            SiteResponse site,
            List<ParagraphResponse> paragraphs,
            List<FeatureResponse> features
    ) {
    }

    record SiteResponse(
            UUID id,
            String brandName,
            String tagline,
            String heroNote,
            String menuNote,
            String aboutTitle,
            long version
    ) {
    }

    record ParagraphResponse(
            UUID id,
            String body,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record FeatureResponse(
            UUID id,
            String icon,
            String title,
            String text,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record UpdateSiteCommand(
            String brandName,
            String tagline,
            String heroNote,
            String menuNote,
            String aboutTitle,
            long version
    ) {
    }

    record CreateParagraphCommand(
            String body,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateParagraphCommand(
            String body,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record CreateFeatureCommand(
            String icon,
            String title,
            String text,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateFeatureCommand(
            String icon,
            String title,
            String text,
            int sortOrder,
            boolean active,
            long version
    ) {
    }
}
