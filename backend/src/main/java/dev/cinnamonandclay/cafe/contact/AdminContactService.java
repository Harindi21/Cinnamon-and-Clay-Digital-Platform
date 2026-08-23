package dev.cinnamonandclay.cafe.contact;

import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import dev.cinnamonandclay.cafe.audit.AuditAction;
import dev.cinnamonandclay.cafe.audit.AuditTrail;
import dev.cinnamonandclay.cafe.shared.ResourceConflictException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class AdminContactService {

    private static final UUID CONTACT_ID =
            UUID.fromString("40000000-0000-0000-0000-000000000001");

    private final ContactProfileRepository profileRepository;
    private final OpeningHourRepository hourRepository;
    private final SocialLinkRepository socialRepository;
    private final AuditTrail auditTrail;

    AdminContactService(
            ContactProfileRepository profileRepository,
            OpeningHourRepository hourRepository,
            SocialLinkRepository socialRepository,
            AuditTrail auditTrail
    ) {
        this.profileRepository = profileRepository;
        this.hourRepository = hourRepository;
        this.socialRepository = socialRepository;
        this.auditTrail = auditTrail;
    }

    @Transactional(readOnly = true)
    AdminContactResponse getContact() {
        ContactProfileEntity profile = requireProfile();
        List<OpeningHourResponse> hours = hourRepository
                .findByContactProfileIdOrderBySortOrderAscIdAsc(CONTACT_ID)
                .stream()
                .map(AdminContactService::toHour)
                .toList();
        List<SocialLinkResponse> socialLinks = socialRepository
                .findByContactProfileIdOrderBySortOrderAscIdAsc(CONTACT_ID)
                .stream()
                .map(AdminContactService::toSocial)
                .toList();
        return new AdminContactResponse(
                toProfile(profile),
                hours,
                socialLinks
        );
    }

    @Transactional
    ProfileResponse updateProfile(UpdateProfileCommand command) {
        ContactProfileEntity profile = requireProfile();
        assertVersion(profile.version(), command.version(), "contact profile");
        ProfileResponse before = toProfile(profile);
        profile.update(
                normalize(command.address()),
                normalize(command.phone()),
                command.email().trim().toLowerCase(Locale.ROOT),
                normalize(command.mapEmbedUrl()),
                command.whatsappEnabled(),
                nullableTrim(command.whatsappNumber()),
                command.whatsappPrefill().trim()
        );
        ProfileResponse after = toProfile(profileRepository.saveAndFlush(profile));
        auditTrail.record(
                AuditAction.UPDATE,
                "contact.profile",
                CONTACT_ID,
                before,
                after
        );
        return after;
    }

    @Transactional
    OpeningHourResponse createOpeningHour(CreateOpeningHourCommand command) {
        requireProfile();
        OpeningHourEntity hour = OpeningHourEntity.create(
                CONTACT_ID,
                normalize(command.dayLabel()),
                normalize(command.timeLabel()),
                command.sortOrder(),
                command.active()
        );
        OpeningHourResponse created = toHour(hourRepository.saveAndFlush(hour));
        auditTrail.record(
                AuditAction.CREATE,
                "contact.opening-hour",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    OpeningHourResponse updateOpeningHour(
            UUID hourId,
            UpdateOpeningHourCommand command
    ) {
        OpeningHourEntity hour = requireHour(hourId);
        assertVersion(hour.version(), command.version(), "opening hour");
        OpeningHourResponse before = toHour(hour);
        hour.update(
                normalize(command.dayLabel()),
                normalize(command.timeLabel()),
                command.sortOrder(),
                command.active()
        );
        OpeningHourResponse after = toHour(hourRepository.saveAndFlush(hour));
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "contact.opening-hour",
                hourId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateOpeningHour(UUID hourId, long version) {
        OpeningHourEntity hour = requireHour(hourId);
        assertVersion(hour.version(), version, "opening hour");
        OpeningHourResponse before = toHour(hour);
        hour.deactivate();
        OpeningHourResponse after = toHour(hourRepository.saveAndFlush(hour));
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "contact.opening-hour",
                hourId,
                before,
                after
        );
    }

    @Transactional
    SocialLinkResponse createSocialLink(CreateSocialLinkCommand command) {
        requireProfile();
        String platform = normalizePlatform(command.platform());
        if (socialRepository.existsByContactProfileIdAndPlatformIgnoreCase(
                CONTACT_ID,
                platform
        )) {
            throw new ResourceConflictException(
                    "A social link already exists for '" + platform + "'."
            );
        }
        SocialLinkEntity link = SocialLinkEntity.create(
                CONTACT_ID,
                platform,
                normalize(command.url()),
                command.sortOrder(),
                command.active()
        );
        SocialLinkResponse created = toSocial(socialRepository.saveAndFlush(link));
        auditTrail.record(
                AuditAction.CREATE,
                "contact.social-link",
                created.id(),
                null,
                created
        );
        return created;
    }

    @Transactional
    SocialLinkResponse updateSocialLink(
            UUID linkId,
            UpdateSocialLinkCommand command
    ) {
        SocialLinkEntity link = requireSocialLink(linkId);
        assertVersion(link.version(), command.version(), "social link");
        SocialLinkResponse before = toSocial(link);
        String platform = normalizePlatform(command.platform());
        if (socialRepository.existsByContactProfileIdAndPlatformIgnoreCaseAndIdNot(
                CONTACT_ID,
                platform,
                linkId
        )) {
            throw new ResourceConflictException(
                    "A social link already exists for '" + platform + "'."
            );
        }
        link.update(
                platform,
                normalize(command.url()),
                command.sortOrder(),
                command.active()
        );
        SocialLinkResponse after = toSocial(socialRepository.saveAndFlush(link));
        auditTrail.record(
                activeChangeAction(before.active(), after.active()),
                "contact.social-link",
                linkId,
                before,
                after
        );
        return after;
    }

    @Transactional
    void deactivateSocialLink(UUID linkId, long version) {
        SocialLinkEntity link = requireSocialLink(linkId);
        assertVersion(link.version(), version, "social link");
        SocialLinkResponse before = toSocial(link);
        link.deactivate();
        SocialLinkResponse after = toSocial(socialRepository.saveAndFlush(link));
        auditTrail.record(
                AuditAction.DEACTIVATE,
                "contact.social-link",
                linkId,
                before,
                after
        );
    }

    private ContactProfileEntity requireProfile() {
        return profileRepository.findById(CONTACT_ID)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Contact profile is not configured."
                ));
    }

    private OpeningHourEntity requireHour(UUID id) {
        return hourRepository.findById(id)
                .filter(hour -> CONTACT_ID.equals(hour.contactProfileId()))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Opening hour " + id + " was not found."
                ));
    }

    private SocialLinkEntity requireSocialLink(UUID id) {
        return socialRepository.findById(id)
                .filter(link -> CONTACT_ID.equals(link.contactProfileId()))
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Social link " + id + " was not found."
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

    private static String normalizePlatform(String value) {
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private static String nullableTrim(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static ProfileResponse toProfile(ContactProfileEntity profile) {
        return new ProfileResponse(
                profile.id(),
                profile.address(),
                profile.phone(),
                profile.email(),
                profile.mapEmbedUrl(),
                profile.whatsappEnabled(),
                profile.whatsappNumberE164(),
                profile.whatsappPrefill(),
                profile.version()
        );
    }

    private static OpeningHourResponse toHour(OpeningHourEntity hour) {
        return new OpeningHourResponse(
                hour.id(),
                hour.dayLabel(),
                hour.timeLabel(),
                hour.sortOrder(),
                hour.active(),
                hour.version()
        );
    }

    private static SocialLinkResponse toSocial(SocialLinkEntity link) {
        return new SocialLinkResponse(
                link.id(),
                link.platform(),
                link.url(),
                link.sortOrder(),
                link.active(),
                link.version()
        );
    }

    record AdminContactResponse(
            ProfileResponse profile,
            List<OpeningHourResponse> hours,
            List<SocialLinkResponse> socialLinks
    ) {
    }

    record ProfileResponse(
            UUID id,
            String address,
            String phone,
            String email,
            String mapEmbedUrl,
            boolean whatsappEnabled,
            String whatsappNumber,
            String whatsappPrefill,
            long version
    ) {
    }

    record OpeningHourResponse(
            UUID id,
            String dayLabel,
            String timeLabel,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record SocialLinkResponse(
            UUID id,
            String platform,
            String url,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record UpdateProfileCommand(
            String address,
            String phone,
            String email,
            String mapEmbedUrl,
            boolean whatsappEnabled,
            String whatsappNumber,
            String whatsappPrefill,
            long version
    ) {
    }

    record CreateOpeningHourCommand(
            String dayLabel,
            String timeLabel,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateOpeningHourCommand(
            String dayLabel,
            String timeLabel,
            int sortOrder,
            boolean active,
            long version
    ) {
    }

    record CreateSocialLinkCommand(
            String platform,
            String url,
            int sortOrder,
            boolean active
    ) {
    }

    record UpdateSocialLinkCommand(
            String platform,
            String url,
            int sortOrder,
            boolean active,
            long version
    ) {
    }
}
