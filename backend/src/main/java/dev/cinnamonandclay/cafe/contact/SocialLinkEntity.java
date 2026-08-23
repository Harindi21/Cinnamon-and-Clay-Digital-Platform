package dev.cinnamonandclay.cafe.contact;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

@Entity
@Table(name = "social_link")
class SocialLinkEntity {

    @Id
    private UUID id;

    @Column(name = "contact_profile_id", nullable = false)
    private UUID contactProfileId;

    @Column(nullable = false, length = 40)
    private String platform;

    @Column(nullable = false, length = 1000)
    private String url;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false)
    private boolean active;

    @Version
    @Column(nullable = false)
    private long version;

    protected SocialLinkEntity() {
    }

    String platform() {
        return platform;
    }

    String url() {
        return url;
    }
}