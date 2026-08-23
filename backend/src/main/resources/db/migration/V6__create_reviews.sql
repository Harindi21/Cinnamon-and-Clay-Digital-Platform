CREATE TABLE review (
    id UUID PRIMARY KEY,

    author_name VARCHAR(120) NOT NULL,

    body VARCHAR(1000) NOT NULL,

    rating SMALLINT NOT NULL
        CHECK (rating BETWEEN 1 AND 5),

    status VARCHAR(20) NOT NULL,

    sort_order INTEGER NOT NULL DEFAULT 0
        CHECK (sort_order >= 0),

    published_at TIMESTAMPTZ,

    version BIGINT NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_review_status
        CHECK (
            status IN (
                'DRAFT',
                'PUBLISHED',
                'HIDDEN'
            )
        ),

    CONSTRAINT ck_review_published_at
        CHECK (
            status <> 'PUBLISHED'
            OR published_at IS NOT NULL
        )
);

CREATE INDEX idx_review_public_order
    ON review(status, sort_order, published_at DESC);