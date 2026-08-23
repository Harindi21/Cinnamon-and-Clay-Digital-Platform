package dev.cinnamonandclay.cafe.contact;

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
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@RestController
@RequestMapping("/api/v1/admin/contact")
class AdminContactController {

    private final AdminContactService service;

    AdminContactController(AdminContactService service) {
        this.service = service;
    }

    @GetMapping
    AdminContactService.AdminContactResponse getContact() {
        return service.getContact();
    }

    @PutMapping("/profile")
    AdminContactService.ProfileResponse updateProfile(
            @Valid @RequestBody ProfileUpdateRequest request
    ) {
        return service.updateProfile(new AdminContactService.UpdateProfileCommand(
                request.address(),
                request.phone(),
                request.email(),
                request.mapEmbedUrl(),
                request.whatsappEnabled(),
                request.whatsappNumber(),
                request.whatsappPrefill(),
                request.version()
        ));
    }

    @PostMapping("/hours")
    ResponseEntity<AdminContactService.OpeningHourResponse> createHour(
            @Valid @RequestBody OpeningHourCreateRequest request
    ) {
        AdminContactService.OpeningHourResponse created = service.createOpeningHour(
                new AdminContactService.CreateOpeningHourCommand(
                        request.dayLabel(),
                        request.timeLabel(),
                        request.sortOrder(),
                        request.active()
                )
        );
        return ResponseEntity.created(
                URI.create("/api/v1/admin/contact/hours/" + created.id())
        ).body(created);
    }

    @PutMapping("/hours/{hourId}")
    AdminContactService.OpeningHourResponse updateHour(
            @PathVariable UUID hourId,
            @Valid @RequestBody OpeningHourUpdateRequest request
    ) {
        return service.updateOpeningHour(
                hourId,
                new AdminContactService.UpdateOpeningHourCommand(
                        request.dayLabel(),
                        request.timeLabel(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/hours/{hourId}")
    ResponseEntity<Void> deactivateHour(
            @PathVariable UUID hourId,
            @RequestParam long version
    ) {
        service.deactivateOpeningHour(hourId, version);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/social-links")
    ResponseEntity<AdminContactService.SocialLinkResponse> createSocialLink(
            @Valid @RequestBody SocialLinkCreateRequest request
    ) {
        AdminContactService.SocialLinkResponse created = service.createSocialLink(
                new AdminContactService.CreateSocialLinkCommand(
                        request.platform(),
                        request.url(),
                        request.sortOrder(),
                        request.active()
                )
        );
        return ResponseEntity.created(
                URI.create("/api/v1/admin/contact/social-links/" + created.id())
        ).body(created);
    }

    @PutMapping("/social-links/{linkId}")
    AdminContactService.SocialLinkResponse updateSocialLink(
            @PathVariable UUID linkId,
            @Valid @RequestBody SocialLinkUpdateRequest request
    ) {
        return service.updateSocialLink(
                linkId,
                new AdminContactService.UpdateSocialLinkCommand(
                        request.platform(),
                        request.url(),
                        request.sortOrder(),
                        request.active(),
                        request.version()
                )
        );
    }

    @DeleteMapping("/social-links/{linkId}")
    ResponseEntity<Void> deactivateSocialLink(
            @PathVariable UUID linkId,
            @RequestParam long version
    ) {
        service.deactivateSocialLink(linkId, version);
        return ResponseEntity.noContent().build();
    }

    record ProfileUpdateRequest(
            @NotBlank @Size(max = 500) String address,
            @NotBlank @Size(max = 80) String phone,
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank @Size(max = 1000)
            @Pattern(regexp = "^https://\\S+$", message = "must be an HTTPS URL")
            String mapEmbedUrl,
            boolean whatsappEnabled,
            @Size(max = 32)
            @Pattern(
                    regexp = "^$|^\\+[1-9]\\d{7,14}$",
                    message = "must be an E.164 number such as +94771234567"
            )
            String whatsappNumber,
            @NotNull @Size(max = 500) String whatsappPrefill,
            @NotNull @Min(0) Long version
    ) {
        @AssertTrue(message = "whatsappNumber is required when WhatsApp is enabled")
        public boolean isWhatsappConfigurationValid() {
            return !whatsappEnabled
                    || (whatsappNumber != null && !whatsappNumber.isBlank());
        }
    }

    record OpeningHourCreateRequest(
            @NotBlank @Size(max = 120) String dayLabel,
            @NotBlank @Size(max = 120) String timeLabel,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record OpeningHourUpdateRequest(
            @NotBlank @Size(max = 120) String dayLabel,
            @NotBlank @Size(max = 120) String timeLabel,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }

    record SocialLinkCreateRequest(
            @NotBlank @Size(max = 40)
            @Pattern(
                    regexp = "^[A-Za-z0-9][A-Za-z0-9-]{0,39}$",
                    message = "must contain only letters, numbers or hyphens"
            )
            String platform,
            @NotBlank @Size(max = 1000)
            @Pattern(regexp = "^https://\\S+$", message = "must be an HTTPS URL")
            String url,
            @Min(0) int sortOrder,
            boolean active
    ) {
    }

    record SocialLinkUpdateRequest(
            @NotBlank @Size(max = 40)
            @Pattern(
                    regexp = "^[A-Za-z0-9][A-Za-z0-9-]{0,39}$",
                    message = "must contain only letters, numbers or hyphens"
            )
            String platform,
            @NotBlank @Size(max = 1000)
            @Pattern(regexp = "^https://\\S+$", message = "must be an HTTPS URL")
            String url,
            @Min(0) int sortOrder,
            boolean active,
            @NotNull @Min(0) Long version
    ) {
    }
}
