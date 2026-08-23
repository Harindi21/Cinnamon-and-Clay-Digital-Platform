package dev.cinnamonandclay.cafe.catalog;

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
@Table(name = "menu_item")
class MenuItemEntity {

    @Id
    private UUID id;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Column(nullable = false, length = 160)
    private String name;

    @Column(nullable = false, length = 500)
    private String description;

    @Column(name = "price_minor", nullable = false)
    private long priceMinor;

    @Column(nullable = false, length = 3)
    private String currency;

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

    protected MenuItemEntity() {
    }

    static MenuItemEntity create(
            UUID categoryId,
            String name,
            String description,
            long priceMinor,
            String currency,
            int sortOrder,
            boolean active
    ) {
        MenuItemEntity item = new MenuItemEntity();
        item.id = UUID.randomUUID();
        item.categoryId = categoryId;
        item.name = name;
        item.description = description;
        item.priceMinor = priceMinor;
        item.currency = currency;
        item.sortOrder = sortOrder;
        item.active = active;
        item.version = 0;
        return item;
    }

    void update(
            UUID categoryId,
            String name,
            String description,
            long priceMinor,
            String currency,
            int sortOrder,
            boolean active
    ) {
        this.categoryId = categoryId;
        this.name = name;
        this.description = description;
        this.priceMinor = priceMinor;
        this.currency = currency;
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

    UUID categoryId() {
        return categoryId;
    }

    String name() {
        return name;
    }

    String description() {
        return description;
    }

    long priceMinor() {
        return priceMinor;
    }

    String currency() {
        return currency;
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
