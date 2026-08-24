ALTER TABLE media_asset
    ADD COLUMN caption VARCHAR(500) NOT NULL DEFAULT '',
    ADD COLUMN focal_x_percent INTEGER NOT NULL DEFAULT 50,
    ADD COLUMN focal_y_percent INTEGER NOT NULL DEFAULT 50;

ALTER TABLE media_asset
    ADD CONSTRAINT ck_media_asset_focal_x_percent
        CHECK (focal_x_percent BETWEEN 0 AND 100),
    ADD CONSTRAINT ck_media_asset_focal_y_percent
        CHECK (focal_y_percent BETWEEN 0 AND 100);

COMMENT ON COLUMN media_asset.caption IS
    'Optional customer-facing caption. Empty means no caption is rendered.';

COMMENT ON COLUMN media_asset.focal_x_percent IS
    'Horizontal crop focal point from 0 (left) to 100 (right).';

COMMENT ON COLUMN media_asset.focal_y_percent IS
    'Vertical crop focal point from 0 (top) to 100 (bottom).';

-- Match the deterministic public/admin ordering query, including the UUID tie-breaker.
DROP INDEX idx_media_asset_public_order;
CREATE INDEX idx_media_asset_public_order
    ON media_asset(purpose, active, sort_order, id);
