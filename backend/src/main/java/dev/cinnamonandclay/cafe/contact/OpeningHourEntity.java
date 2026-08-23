package dev.cinnamonandclay.cafe.contact;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

@Entity
@Table(name = "opening_hour")
class OpeningHourEntity {

    @Id
    private UUID id;

    @Column(name = "contact_profile_id", nullable = false)
    private UUID contactProfileId;

    @Column(name = "day_label", nullable = false, length = 120)
    private String dayLabel;

    @Column(name = "time_label", nullable = false, length = 120)
    private String timeLabel;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(nullable = false)
    private boolean active;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected OpeningHourEntity() {
    }

    static OpeningHourEntity create(
            UUID contactProfileId,
            String dayLabel,
            String timeLabel,
            int sortOrder,
            boolean active
    ) {
        OpeningHourEntity hour = new OpeningHourEntity();
        hour.id = UUID.randomUUID();
        hour.contactProfileId = contactProfileId;
        hour.dayLabel = dayLabel;
        hour.timeLabel = timeLabel;
        hour.sortOrder = sortOrder;
        hour.active = active;
        hour.version = 0;
        return hour;
    }

    void update(
            String dayLabel,
            String timeLabel,
            int sortOrder,
            boolean active
    ) {
        this.dayLabel = dayLabel;
        this.timeLabel = timeLabel;
        this.sortOrder = sortOrder;
        this.active = active;
    }

    void deactivate() {
        active = false;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    UUID id() {
        return id;
    }

    UUID contactProfileId() {
        return contactProfileId;
    }

    String dayLabel() {
        return dayLabel;
    }

    String timeLabel() {
        return timeLabel;
    }

    int sortOrder() {
        return sortOrder;
    }

    boolean active() {
        return active;
    }

    long version() {
        return version;
    }
}
