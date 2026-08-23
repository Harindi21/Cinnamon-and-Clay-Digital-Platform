package dev.cinnamonandclay.cafe.media;

record InspectedMediaFile(
        byte[] bytes,
        String originalFilename,
        String contentType,
        String extension,
        int widthPixels,
        int heightPixels,
        String checksumSha256
) {
    long sizeBytes() {
        return bytes.length;
    }
}
