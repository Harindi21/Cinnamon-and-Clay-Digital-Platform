package dev.cinnamonandclay.cafe.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.util.UUID;

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

    protected MenuItemEntity() {
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
}
