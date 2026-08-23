INSERT INTO review (
    id,
    author_name,
    body,
    rating,
    status,
    sort_order,
    published_at
) VALUES
(
    '60000000-0000-0000-0000-000000000001',
    'Dinithi P.',
    'Best cinnamon rolls in Colombo, hands down. The coffee is a bonus.',
    5,
    'PUBLISHED',
    10,
    CURRENT_TIMESTAMP
),
(
    '60000000-0000-0000-0000-000000000002',
    'Ashan W.',
    'Quiet, cosy, great Wi-Fi. I basically work from here now.',
    5,
    'PUBLISHED',
    20,
    CURRENT_TIMESTAMP
),
(
    '60000000-0000-0000-0000-000000000003',
    'Savindu B.',
    'Lovely spot for a slow Sunday breakfast. Staff are so warm.',
    4,
    'PUBLISHED',
    30,
    CURRENT_TIMESTAMP
);