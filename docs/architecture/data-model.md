# Current persistent data model

Cinnamon & Clay stores structured business data in PostgreSQL.

Media binary content is stored in object storage. PostgreSQL stores only media metadata and object keys.

```mermaid
erDiagram
    MENU_CATEGORY ||--o{ MENU_ITEM : contains

    SITE_CONTENT ||--o{ SITE_ABOUT_PARAGRAPH : contains
    SITE_CONTENT ||--o{ SITE_FEATURE : contains

    CONTACT_PROFILE ||--o{ OPENING_HOUR : contains
    CONTACT_PROFILE ||--o{ SOCIAL_LINK : contains

    MENU_CATEGORY {
        uuid id PK
        varchar slug UK
        varchar name
        int sort_order
        boolean active
        bigint version
    }

    MENU_ITEM {
        uuid id PK
        uuid category_id FK
        varchar name
        varchar description
        bigint price_minor
        varchar currency
        int sort_order
        boolean active
        bigint version
    }

    SITE_CONTENT {
        uuid id PK
        varchar brand_name
        varchar tagline
        varchar hero_note
        varchar menu_note
        varchar about_title
        bigint version
    }

    SITE_ABOUT_PARAGRAPH {
        uuid id PK
        uuid site_content_id FK
        varchar body
        int sort_order
        boolean active
        bigint version
    }

    SITE_FEATURE {
        uuid id PK
        uuid site_content_id FK
        varchar icon
        varchar title
        varchar text
        int sort_order
        boolean active
        bigint version
    }

    CONTACT_PROFILE {
        uuid id PK
        varchar address
        varchar phone
        varchar email
        varchar map_embed_url
        boolean whatsapp_enabled
        varchar whatsapp_number_e164
        varchar whatsapp_prefill
        bigint version
    }

    OPENING_HOUR {
        uuid id PK
        uuid contact_profile_id FK
        varchar day_label
        varchar time_label
        int sort_order
        boolean active
        bigint version
    }

    SOCIAL_LINK {
        uuid id PK
        uuid contact_profile_id FK
        varchar platform
        varchar url
        int sort_order
        boolean active
        bigint version
    }

    MEDIA_ASSET {
        uuid id PK
        varchar object_key UK
        varchar original_filename
        varchar content_type
        bigint size_bytes
        varchar purpose
        varchar alt_text
        int sort_order
        boolean active
        int width_pixels
        int height_pixels
        varchar checksum_sha256
        bigint version
    }

    REVIEW {
        uuid id PK
        varchar author_name
        varchar body
        smallint rating
        varchar status
        int sort_order
        timestamptz published_at
        bigint version
    }

    ADMIN_AUDIT_EVENT {
        uuid id PK
        timestamptz occurred_at
        varchar actor_subject
        varchar actor_username
        jsonb actor_roles
        varchar action
        varchar resource_type
        varchar resource_id
        varchar request_id
        varchar trace_id
        jsonb before_state
        jsonb after_state
        jsonb metadata
    }
```

`ADMIN_AUDIT_EVENT` is intentionally append-only. A PostgreSQL trigger rejects update, delete and truncate operations; normal application access is read-only outside insertion through the audit service. It deliberately has no foreign keys to mutable business tables so historical events survive resource deactivation and future lifecycle changes.
