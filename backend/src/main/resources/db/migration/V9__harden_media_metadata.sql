ALTER TABLE media_asset
    ADD COLUMN width_pixels INTEGER,
    ADD COLUMN height_pixels INTEGER,
    ADD COLUMN checksum_sha256 VARCHAR(64);

ALTER TABLE media_asset
    ADD CONSTRAINT ck_media_asset_width_pixels
        CHECK (width_pixels IS NULL OR width_pixels > 0),
    ADD CONSTRAINT ck_media_asset_height_pixels
        CHECK (height_pixels IS NULL OR height_pixels > 0),
    ADD CONSTRAINT ck_media_asset_checksum_sha256
        CHECK (
            checksum_sha256 IS NULL
            OR checksum_sha256 ~ '^[0-9a-f]{64}$'
        );

-- Preserve the earliest configured active singleton if legacy/manual data contains
-- duplicates. This makes the migration safe before the database invariant is added.
WITH ranked_singletons AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY purpose
            ORDER BY sort_order ASC, id ASC
        ) AS singleton_rank
    FROM media_asset
    WHERE active = TRUE
      AND purpose IN ('HERO', 'ABOUT')
)
UPDATE media_asset AS asset
SET active = FALSE,
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
FROM ranked_singletons AS ranked
WHERE asset.id = ranked.id
  AND ranked.singleton_rank > 1;

CREATE UNIQUE INDEX uq_media_asset_singleton_active
    ON media_asset(purpose)
    WHERE active = TRUE
      AND purpose IN ('HERO', 'ABOUT');
