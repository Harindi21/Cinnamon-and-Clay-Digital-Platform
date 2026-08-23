package dev.cinnamonandclay.cafe.media;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "media.storage")
record MediaProperties(
        String endpoint,
        String region,
        String bucket,
        String accessKey,
        String secretKey
) {
}