package dev.cinnamonandclay.cafe.media;

enum MediaPurpose {
    HERO(true),
    ABOUT(true),
    GALLERY(false);

    private final boolean singleton;

    MediaPurpose(boolean singleton) {
        this.singleton = singleton;
    }

    boolean isSingleton() {
        return singleton;
    }

    String objectPrefix() {
        return name().toLowerCase();
    }
}
