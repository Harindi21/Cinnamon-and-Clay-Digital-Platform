package dev.cinnamonandclay.cafe.catalog;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.UUID;

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

    protected MenuCategoryEntity() {
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
}
