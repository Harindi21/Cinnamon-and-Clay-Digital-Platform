package dev.cinnamonandclay.cafe.publishing;

import java.net.URI;
import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.public-cache")
record PublicCacheInvalidationProperties(
        boolean enabled,
        URI revalidationUrl,
        String secret,
        Duration timeout
) {
    PublicCacheInvalidationProperties {
        timeout = timeout == null ? Duration.ofSeconds(1) : timeout;
    }
}
