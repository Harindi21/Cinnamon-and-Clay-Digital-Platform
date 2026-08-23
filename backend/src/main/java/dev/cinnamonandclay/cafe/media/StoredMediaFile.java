package dev.cinnamonandclay.cafe.media;

record StoredMediaFile(
        String objectKey,
        String originalFilename,
        String contentType,
        long sizeBytes,
        int widthPixels,
        int heightPixels,
        String checksumSha256
) {
}
