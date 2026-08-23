package dev.cinnamonandclay.cafe.contact;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

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

    protected OpeningHourEntity() {
    }

    String dayLabel() {
        return dayLabel;
    }

    String timeLabel() {
        return timeLabel;
    }
}