from __future__ import annotations

import os
from collections.abc import Iterator

import pytest
from playwright.sync_api import Browser, Page, Playwright, expect, sync_playwright

WEB_BASE_URL = os.environ.get("E2E_WEB_BASE_URL", "http://127.0.0.1:3000")
FIRST_GALLERY_ID = "33333333-3333-4333-8333-333333333331"


@pytest.fixture(scope="session")
def playwright_instance() -> Iterator[Playwright]:
    with sync_playwright() as instance:
        yield instance


@pytest.fixture(scope="session")
def browser(playwright_instance: Playwright) -> Iterator[Browser]:
    browser = playwright_instance.chromium.launch(headless=True)
    yield browser
    browser.close()


@pytest.fixture
def page(browser: Browser) -> Iterator[Page]:
    context = browser.new_context(viewport={"width": 1440, "height": 1000})
    page = context.new_page()
    yield page
    context.close()


def test_public_home_renders_end_to_end_content(page: Page) -> None:
    response = page.goto(WEB_BASE_URL, wait_until="networkidle")
    assert response is not None and response.ok

    navigation = page.get_by_role("navigation", name="Primary")
    expect(navigation.get_by_role("link", name="About")).to_have_attribute("href", "#about")
    expect(navigation.get_by_role("link", name="Menu")).to_have_attribute("href", "#menu")
    expect(navigation.get_by_role("link", name="Visit Us")).to_have_attribute("href", "#visit")
    expect(page.get_by_role("heading", name="Cinnamon & Clay", exact=True)).to_be_visible()
    expect(page.get_by_role("heading", name="The Menu")).to_be_visible()
    expect(page.get_by_role("heading", name="Coffee", exact=True)).to_be_visible()
    expect(page.get_by_text("Cinnamon Flat White", exact=True)).to_be_visible()
    expect(page.get_by_role("heading", name="Gallery", exact=True)).to_be_visible()
    expect(page.get_by_label("Cafe gallery").locator("figure")).to_have_count(3)
    expect(page.get_by_role("heading", name="What People Say")).to_be_visible()
    expect(page.get_by_text("— Ari", exact=True)).to_be_visible()
    expect(page.get_by_role("heading", name="Visit Us")).to_be_visible()
    expect(page.get_by_role("link", name="Order on WhatsApp")).to_have_attribute(
        "href", r"https://wa.me/94770000000?text=Hello%20Cinnamon%20%26%20Clay"
    )


def test_mobile_navigation_opens_and_closes_with_keyboard(page: Page) -> None:
    page.set_viewport_size({"width": 390, "height": 844})
    page.goto(WEB_BASE_URL, wait_until="networkidle")

    toggle = page.get_by_role("button", name="Open navigation menu")
    toggle.click()

    expect(page.get_by_role("link", name="About")).to_be_visible()
    page.keyboard.press("Escape")
    expect(page.get_by_role("button", name="Open navigation menu")).to_be_focused()


def test_gallery_lightbox_keyboard_navigation_and_focus_restore(page: Page) -> None:
    page.goto(WEB_BASE_URL, wait_until="networkidle")
    opener = page.get_by_role("button", name="Open gallery image 1 of 3: Fresh cardamom buns on a tray")
    opener.click()

    dialog = page.get_by_role("dialog", name="Gallery image 1 of 3")
    expect(dialog).to_be_visible()
    expect(page.get_by_role("button", name="Close gallery")).to_be_focused()

    page.keyboard.press("ArrowRight")
    expect(page.get_by_role("dialog", name="Gallery image 2 of 3")).to_be_visible()
    expect(page.get_by_text("2 / 3", exact=True)).to_be_visible()

    page.keyboard.press("End")
    expect(page.get_by_role("dialog", name="Gallery image 3 of 3")).to_be_visible()

    page.keyboard.press("Escape")
    expect(page.get_by_role("dialog")).to_have_count(0)
    expect(opener).to_be_focused()


def test_public_media_proxy_preserves_safe_headers(page: Page) -> None:
    response = page.request.get(f"{WEB_BASE_URL}/media/{FIRST_GALLERY_ID}?v=1")
    assert response.status == 200
    headers = response.headers
    assert headers["content-type"].startswith("image/png")
    assert headers["x-content-type-options"] == "nosniff"
    assert "public" in headers["cache-control"]


def test_web_readiness_reports_backend_dependency(page: Page) -> None:
    response = page.request.get(f"{WEB_BASE_URL}/api/health/ready")
    assert response.status == 200
    assert response.json() == {
        "status": "UP",
        "dependencies": {"backend": "UP"},
    }
    assert response.headers["cache-control"] == "no-store"


def test_mobile_layout_has_no_horizontal_overflow_and_gallery_still_operates(page: Page) -> None:
    page.set_viewport_size({"width": 390, "height": 844})
    page.goto(WEB_BASE_URL, wait_until="networkidle")

    overflow = page.evaluate(
        "document.documentElement.scrollWidth - document.documentElement.clientWidth"
    )
    assert overflow <= 1

    page.get_by_role("button", name="Open gallery image 2 of 3: A ceramic cup of flat white").click()
    expect(page.get_by_role("dialog", name="Gallery image 2 of 3")).to_be_visible()
    page.get_by_role("button", name="Close gallery").click()
    expect(page.get_by_role("dialog")).to_have_count(0)
