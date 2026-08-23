ALTER TABLE menu_category
    ADD COLUMN version BIGINT NOT NULL DEFAULT 0;

CREATE INDEX idx_menu_category_admin_order
    ON menu_category(sort_order, name);

CREATE INDEX idx_menu_item_admin_order
    ON menu_item(category_id, sort_order, name);
