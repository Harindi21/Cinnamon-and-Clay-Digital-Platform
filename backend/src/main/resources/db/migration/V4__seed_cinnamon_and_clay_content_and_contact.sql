INSERT INTO site_content (
    id,
    brand_name,
    tagline,
    hero_note,
    menu_note,
    about_title
) VALUES (
    '30000000-0000-0000-0000-000000000001',
    'Cinnamon & Clay',
    'Slow coffee. Warm bakes. Good company.',
    'A neighbourhood coffee house in the heart of Colombo.',
    'Prices in Sri Lankan Rupees. Ask us about today''s specials!',
    'Our little story'
);

INSERT INTO site_about_paragraph (
    id,
    site_content_id,
    body,
    sort_order
) VALUES
(
    '31000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'Cinnamon & Clay began with one espresso machine, a family recipe for cinnamon rolls, and a stubborn belief that Colombo deserves coffee worth slowing down for.',
    10
),
(
    '31000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'Every bean is roasted locally, every bake comes out of our own oven each morning, and every guest gets a table for as long as they need it.',
    20
);

INSERT INTO site_feature (
    id,
    site_content_id,
    icon,
    title,
    text,
    sort_order
) VALUES
(
    '32000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '🌱',
    'Locally roasted',
    'Beans from Sri Lankan highland roasters, ground to order.',
    10
),
(
    '32000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    '🥐',
    'Baked daily',
    'Pastries and cakes from our oven, every single morning.',
    20
),
(
    '32000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000001',
    '📶',
    'Work friendly',
    'Fast Wi-Fi, plug points, and no one rushing you.',
    30
);

INSERT INTO contact_profile (
    id,
    address,
    phone,
    email,
    map_embed_url,
    whatsapp_enabled,
    whatsapp_number_e164,
    whatsapp_prefill
) VALUES (
    '40000000-0000-0000-0000-000000000001',
    '42 Flower Road, Colombo 07, Sri Lanka',
    '+94 77 123 4567',
    'hello@cinnamonandclay.lk',
    'https://www.google.com/maps?q=Colombo+07,+Sri+Lanka&output=embed',
    TRUE,
    '+94771234567',
    'Hi! I''d like to place an order 🙂'
);

INSERT INTO opening_hour (
    id,
    contact_profile_id,
    day_label,
    time_label,
    sort_order
) VALUES
(
    '41000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'Monday – Friday',
    '7.30 am – 7.00 pm',
    10
),
(
    '41000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000001',
    'Saturday',
    '8.00 am – 9.00 pm',
    20
),
(
    '41000000-0000-0000-0000-000000000003',
    '40000000-0000-0000-0000-000000000001',
    'Sunday',
    '8.00 am – 5.00 pm',
    30
);

INSERT INTO social_link (
    id,
    contact_profile_id,
    platform,
    url,
    sort_order
) VALUES
(
    '42000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'instagram',
    'https://instagram.com/',
    10
),
(
    '42000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000001',
    'facebook',
    'https://facebook.com/',
    20
);
