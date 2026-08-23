package dev.cinnamonandclay.cafe.media;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "media.upload")
record MediaUploadProperties(
        long maxBytes,
        int maxWidth,
        int maxHeight,
        long maxPixels,
        Duration orphanGracePeriod
) {
    MediaUploadProperties {
        if (maxBytes <= 0) {
            throw new IllegalArgumentException("media.upload.max-bytes must be positive");
        }
        if (maxWidth <= 0 || maxHeight <= 0 || maxPixels <= 0) {
            throw new IllegalArgumentException("media.upload image limits must be positive");
        }
        if (orphanGracePeriod == null || orphanGracePeriod.isNegative()) {
            throw new IllegalArgumentException(
                    "media.upload.orphan-grace-period must not be negative"
            );
        }
    }
}
