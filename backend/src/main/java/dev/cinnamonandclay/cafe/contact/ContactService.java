package dev.cinnamonandclay.cafe.contact;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
class ContactService {

    private static final UUID CONTACT_ID =
            UUID.fromString("40000000-0000-0000-0000-000000000001");

    private final ContactProfileRepository profileRepository;
    private final OpeningHourRepository hourRepository;
    private final SocialLinkRepository socialRepository;

    ContactService(
            ContactProfileRepository profileRepository,
            OpeningHourRepository hourRepository,
            SocialLinkRepository socialRepository
    ) {
        this.profileRepository = profileRepository;
        this.hourRepository = hourRepository;
        this.socialRepository = socialRepository;
    }

    @Transactional(readOnly = true)
    ContactResponse getPublicContact() {
        var profile = profileRepository.findById(CONTACT_ID)
                .orElseThrow(() ->
                        new IllegalStateException("Contact profile is missing")
                );

        List<OpeningHourResponse> hours = hourRepository
                .findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(CONTACT_ID)
                .stream()
                .map(hour -> new OpeningHourResponse(
                        hour.dayLabel(),
                        hour.timeLabel()
                ))
                .toList();

        List<SocialLinkResponse> socialLinks = socialRepository
                .findByContactProfileIdAndActiveTrueOrderBySortOrderAsc(CONTACT_ID)
                .stream()
                .map(link -> new SocialLinkResponse(
                        link.platform(),
                        link.url()
                ))
                .toList();

        return new ContactResponse(
                profile.address(),
                profile.phone(),
                profile.email(),
                profile.mapEmbedUrl(),
                hours,
                new WhatsAppResponse(
                        profile.whatsappEnabled(),
                        profile.whatsappNumberE164(),
                        profile.whatsappPrefill()
                ),
                socialLinks
        );
    }

    record ContactResponse(
            String address,
            String phone,
            String email,
            String mapEmbedUrl,
            List<OpeningHourResponse> hours,
            WhatsAppResponse whatsapp,
            List<SocialLinkResponse> socialLinks
    ) {
    }

    record OpeningHourResponse(
            String day,
            String time
    ) {
    }

    record WhatsAppResponse(
            boolean enabled,
            String number,
            String prefill
    ) {
    }

    record SocialLinkResponse(
            String platform,
            String url
    ) {
    }
}