package dev.cinnamonandclay.cafe.publishing;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import dev.cinnamonandclay.cafe.audit.AdminChangeRecordedEvent;
import io.micrometer.core.instrument.MeterRegistry;

@Component
class PublicCacheInvalidator {

    private static final Logger log = LoggerFactory.getLogger(PublicCacheInvalidator.class);

    private final PublicCacheInvalidationProperties properties;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final MeterRegistry meterRegistry;

    PublicCacheInvalidator(
            PublicCacheInvalidationProperties properties,
            HttpClient httpClient,
            ObjectMapper objectMapper,
            MeterRegistry meterRegistry
    ) {
        this.properties = properties;
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
        this.meterRegistry = meterRegistry;
    }

    @TransactionalEventListener(
            phase = TransactionPhase.AFTER_COMMIT,
            fallbackExecution = true
    )
    void invalidate(AdminChangeRecordedEvent event) {
        List<String> tags = tagsFor(event.resourceType());
        if (tags.isEmpty() || !properties.enabled()) {
            return;
        }

        if (!isConfigured()) {
            recordResult("misconfigured");
            log.warn(
                    "Public cache invalidation is enabled but URL/secret configuration is missing"
            );
            return;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder(properties.revalidationUrl())
                    .timeout(properties.timeout())
                    .header("Content-Type", "application/json")
                    .header("X-Revalidation-Secret", properties.secret())
                    .POST(HttpRequest.BodyPublishers.ofString(body(tags)))
                    .build();

            HttpResponse<Void> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.discarding()
            );

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                recordResult("success");
                log.atInfo()
                        .addKeyValue("cache.tags", String.join(",", tags))
                        .addKeyValue("resource.type", event.resourceType())
                        .log("Public cache invalidated after administrator change");
            } else {
                recordResult("http_error");
                log.atWarn()
                        .addKeyValue("http.status_code", response.statusCode())
                        .addKeyValue("cache.tags", String.join(",", tags))
                        .log("Public cache invalidation endpoint returned an error");
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            recordResult("interrupted");
            log.warn("Public cache invalidation was interrupted");
        } catch (Exception exception) {
            recordResult("failure");
            log.warn("Public cache invalidation failed after a committed change", exception);
        }
    }

    private boolean isConfigured() {
        URI url = properties.revalidationUrl();
        return url != null
                && properties.secret() != null
                && !properties.secret().isBlank();
    }

    private String body(List<String> tags) throws JsonProcessingException {
        return objectMapper.writeValueAsString(Map.of("tags", tags));
    }

    private void recordResult(String result) {
        meterRegistry.counter(
                "cafe.public.cache.invalidation",
                "result", result
        ).increment();
    }

    static List<String> tagsFor(String resourceType) {
        if (resourceType == null) {
            return List.of();
        }
        if (resourceType.startsWith("catalog.")) {
            return List.of("catalog");
        }
        if (resourceType.startsWith("content.")) {
            return List.of("content");
        }
        if (resourceType.startsWith("contact.")) {
            return List.of("contact");
        }
        if (resourceType.equals("media.asset")) {
            return List.of("media");
        }
        if (resourceType.startsWith("reviews.")) {
            return List.of("reviews");
        }
        return List.of();
    }
}
