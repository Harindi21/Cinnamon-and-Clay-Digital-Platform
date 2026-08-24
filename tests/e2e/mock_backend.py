from __future__ import annotations

import argparse
import base64
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR42mNk+M/wn4GBgYGJAQoAHgQCAf9o0YQAAAAASUVORK5CYII="
)

HERO_ID = "11111111-1111-4111-8111-111111111111"
ABOUT_ID = "22222222-2222-4222-8222-222222222222"
GALLERY_IDS = [
    "33333333-3333-4333-8333-333333333331",
    "33333333-3333-4333-8333-333333333332",
    "33333333-3333-4333-8333-333333333333",
]
MEDIA_IDS = {HERO_ID, ABOUT_ID, *GALLERY_IDS}

MENU: dict[str, Any] = {
    "defaultCurrency": "LKR",
    "categories": [
        {
            "id": "11111111-aaaa-4111-8111-111111111111",
            "slug": "coffee",
            "name": "Coffee",
            "items": [
                {
                    "id": "11111111-bbbb-4111-8111-111111111111",
                    "name": "Cinnamon Flat White",
                    "description": "Espresso, steamed milk and a cinnamon finish.",
                    "price": {"amountMinor": 85000, "currency": "LKR"},
                },
                {
                    "id": "11111111-bbbb-4111-8111-111111111112",
                    "name": "Clay Pot Cold Brew",
                    "description": "Slow-steeped coffee served over ice.",
                    "price": {"amountMinor": 90000, "currency": "LKR"},
                },
            ],
        },
        {
            "id": "11111111-aaaa-4111-8111-111111111112",
            "slug": "bakes",
            "name": "Warm Bakes",
            "items": [
                {
                    "id": "11111111-bbbb-4111-8111-111111111113",
                    "name": "Cardamom Bun",
                    "description": "Soft bun with cardamom sugar.",
                    "price": {"amountMinor": 65000, "currency": "LKR"},
                }
            ],
        },
    ],
}

CONTENT: dict[str, Any] = {
    "brand": {
        "name": "Cinnamon & Clay",
        "tagline": "Slow coffee. Warm bakes. Good company.",
        "heroNote": "Neighbourhood coffee house",
    },
    "menuNote": "Small-batch coffee and bakes made for unhurried mornings.",
    "about": {
        "title": "Made for slow mornings",
        "paragraphs": [
            "Cinnamon & Clay is a warm corner for thoughtful coffee and fresh bakes.",
            "We keep the menu small, seasonal and easy to return to.",
        ],
        "features": [
            {"icon": "☕", "title": "Thoughtful coffee", "text": "Carefully dialled every day."},
            {"icon": "🥐", "title": "Warm bakes", "text": "Fresh from the oven."},
            {"icon": "🌿", "title": "Easy pace", "text": "Stay as long as you like."},
        ],
    },
}

CONTACT: dict[str, Any] = {
    "address": "42 Cinnamon Lane, Colombo 07",
    "phone": "+94 11 555 0199",
    "email": "hello@cinnamonandclay.test",
    "mapEmbedUrl": "",
    "hours": [
        {"day": "Monday–Friday", "time": "7:00 AM – 6:00 PM"},
        {"day": "Saturday–Sunday", "time": "8:00 AM – 6:00 PM"},
    ],
    "whatsapp": {
        "enabled": True,
        "number": "+94770000000",
        "prefill": "Hello Cinnamon & Clay",
    },
    "socialLinks": [
        {"platform": "Instagram", "url": "https://example.com/cinnamon-and-clay"}
    ],
}

REVIEWS: dict[str, Any] = {
    "reviews": [
        {
            "id": "44444444-4444-4444-8444-444444444444",
            "authorName": "Ari",
            "body": "Warm room, careful coffee, and the cardamom bun is worth returning for.",
            "rating": 5,
        }
    ]
}


def asset(asset_id: str, alt: str, caption: str, width: int, height: int) -> dict[str, Any]:
    return {
        "id": asset_id,
        "url": f"/api/v1/media/{asset_id}/content",
        "alt": alt,
        "caption": caption,
        "focalXPercent": 50,
        "focalYPercent": 50,
        "width": width,
        "height": height,
        "version": 1,
    }


MEDIA: dict[str, Any] = {
    "hero": asset(HERO_ID, "Coffee being poured at the bar", "", 1600, 900),
    "about": asset(ABOUT_ID, "Cafe table beside a sunlit window", "", 900, 1200),
    "gallery": [
        asset(GALLERY_IDS[0], "Fresh cardamom buns on a tray", "Baked warm every morning.", 1200, 800),
        asset(GALLERY_IDS[1], "A ceramic cup of flat white", "A quiet cup at the bar.", 800, 1200),
        asset(GALLERY_IDS[2], "Friends sharing coffee at a table", "Good coffee, better company.", 1200, 900),
    ],
}


class Handler(BaseHTTPRequestHandler):
    server_version = "CinnamonClayE2E/1.0"

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        payloads: dict[str, dict[str, Any]] = {
            "/api/v1/catalog/menu": MENU,
            "/api/v1/content/site": CONTENT,
            "/api/v1/contact": CONTACT,
            "/api/v1/media": MEDIA,
            "/api/v1/reviews": REVIEWS,
            "/actuator/health": {"status": "UP"},
            "/actuator/health/readiness": {"status": "UP"},
            "/health": {"status": "UP"},
        }

        if path in payloads:
            self._json(200, payloads[path])
            return

        prefix = "/api/v1/media/"
        suffix = "/content"
        if path.startswith(prefix) and path.endswith(suffix):
            asset_id = path[len(prefix) : -len(suffix)]
            if asset_id in MEDIA_IDS:
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(PNG)))
                self.send_header("Cache-Control", "public, max-age=604800, immutable")
                self.send_header("ETag", f'"e2e-{asset_id}"')
                self.end_headers()
                self.wfile.write(PNG)
                return

        self._json(404, {"error": "not_found"})

    def log_message(self, format: str, *args: object) -> None:
        print(f"[mock-backend] {self.address_string()} {format % args}", flush=True)

    def _json(self, status: int, body: dict[str, Any]) -> None:
        encoded = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(encoded)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=18082, type=int)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Mock backend listening on http://{args.host}:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
