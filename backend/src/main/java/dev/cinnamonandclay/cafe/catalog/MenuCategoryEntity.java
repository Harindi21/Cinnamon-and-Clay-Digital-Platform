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
@Table(name = "menu_category")
class MenuCategoryEntity {

    @Id
    private UUID id;

    @Column(nullable = false, unique = true, length = 80)
    private String slug;

    @Column(nullable = false, length = 120)
    private String name;

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

    protected MenuCategoryEntity() {
    }

    static MenuCategoryEntity create(
            String slug,
            String name,
            int sortOrder,
            boolean active
    ) {
        MenuCategoryEntity category = new MenuCategoryEntity();
        category.id = UUID.randomUUID();
        category.slug = slug;
        category.name = name;
        category.sortOrder = sortOrder;
        category.active = active;
        category.version = 0;
        return category;
    }

    void update(
            String slug,
            String name,
            int sortOrder,
            boolean active
    ) {
        this.slug = slug;
        this.name = name;
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

    String slug() {
        return slug;
    }

    String name() {
        return name;
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
