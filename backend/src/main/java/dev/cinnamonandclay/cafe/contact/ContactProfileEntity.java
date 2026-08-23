package dev.cinnamonandclay.cafe.contact;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

@Entity
@Table(name = "contact_profile")
class ContactProfileEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 500)
    private String address;

    @Column(nullable = false, length = 80)
    private String phone;

    @Column(nullable = false, length = 320)
    private String email;

    @Column(name = "map_embed_url", nullable = false, length = 1000)
    private String mapEmbedUrl;

    @Column(name = "whatsapp_enabled", nullable = false)
    private boolean whatsappEnabled;

    @Column(name = "whatsapp_number_e164", length = 32)
    private String whatsappNumberE164;

    @Column(name = "whatsapp_prefill", nullable = false, length = 500)
    private String whatsappPrefill;

    @Version
    @Column(nullable = false)
    private long version;

    protected ContactProfileEntity() {
    }

    String address() {
        return address;
    }

    String phone() {
        return phone;
    }

    String email() {
        return email;
    }

    String mapEmbedUrl() {
        return mapEmbedUrl;
    }

    boolean whatsappEnabled() {
        return whatsappEnabled;
    }

    String whatsappNumberE164() {
        return whatsappNumberE164;
    }

    String whatsappPrefill() {
        return whatsappPrefill;
    }
}