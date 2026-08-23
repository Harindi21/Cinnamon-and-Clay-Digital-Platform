package dev.cinnamonandclay.cafe.audit;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.slf4j.MDC;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.ObjectNode;

@Service
public class AuditTrail {

    private static final int MAX_DEPTH = 8;
    private static final int MAX_ARRAY_ITEMS = 100;
    private static final int MAX_TEXT_LENGTH = 4096;
    private static final Set<String> SENSITIVE_FIELD_PARTS = Set.of(
            "authorization",
            "credential",
            "password",
            "secret",
            "token"
    );

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;
    private final ApplicationEventPublisher eventPublisher;

    public AuditTrail(
            JdbcTemplate jdbcTemplate,
            ObjectMapper objectMapper,
            ApplicationEventPublisher eventPublisher
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
        this.eventPublisher = eventPublisher;
    }

    public void record(
            AuditAction action,
            String resourceType,
            Object resourceId,
            Object beforeState,
            Object afterState
    ) {
        record(
                action,
                resourceType,
                resourceId,
                beforeState,
                afterState,
                Map.of()
        );
    }

    public void record(
            AuditAction action,
            String resourceType,
            Object resourceId,
            Object beforeState,
            Object afterState,
            Map<String, ?> metadata
    ) {
        Actor actor = currentActor();
        String normalizedResourceType = requireText(resourceType, "resourceType");
        String actionName = action.name();

        jdbcTemplate.update(
                """
                INSERT INTO admin_audit_event (
                    id,
                    actor_subject,
                    actor_username,
                    actor_roles,
                    action,
                    resource_type,
                    resource_id,
                    request_id,
                    trace_id,
                    before_state,
                    after_state,
                    metadata
                ) VALUES (
                    ?, ?, ?, CAST(? AS jsonb), ?, ?, ?, ?, ?,
                    CAST(? AS jsonb), CAST(? AS jsonb), CAST(? AS jsonb)
                )
                """,
                UUID.randomUUID(),
                actor.subject(),
                actor.username(),
                toJson(actor.roles()),
                actionName,
                normalizedResourceType,
                resourceId == null ? null : resourceId.toString(),
                normalizeOptional(MDC.get("requestId"), 80),
                normalizeOptional(MDC.get("traceId"), 64),
                toJsonOrNull(beforeState),
                toJsonOrNull(afterState),
                toJson(metadata == null ? Map.of() : metadata)
        );

        eventPublisher.publishEvent(
                new AdminChangeRecordedEvent(
                        action,
                        normalizedResourceType,
                        resourceId == null ? null : resourceId.toString()
                )
        );
    }

    private Actor currentActor() {
        Authentication authentication = SecurityContextHolder
                .getContext()
                .getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            return new Actor("system", "system", List.of("system"));
        }

        String subject = authentication.getName();
        String username = authentication.getName();

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            subject = normalizeActorValue(jwt.getSubject(), authentication.getName());
            username = normalizeActorValue(
                    jwt.getClaimAsString("preferred_username"),
                    authentication.getName()
            );
        }

        List<String> roles = authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .filter(authority -> authority.startsWith("ROLE_"))
                .map(authority -> authority.substring("ROLE_".length()))
                .map(value -> value.toLowerCase(Locale.ROOT))
                .sorted(Comparator.naturalOrder())
                .toList();

        return new Actor(
                normalizeActorValue(subject, "unknown"),
                normalizeActorValue(username, "unknown"),
                roles
        );
    }

    private String toJsonOrNull(Object value) {
        return value == null ? null : toJson(value);
    }

    private String toJson(Object value) {
        JsonNode source = objectMapper.valueToTree(value);
        JsonNode sanitized = sanitize(source, 0);
        try {
            return objectMapper.writeValueAsString(sanitized);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize audit metadata.", exception);
        }
    }

    private JsonNode sanitize(JsonNode node, int depth) {
        if (node == null || node.isNull()) {
            return JsonNodeFactory.instance.nullNode();
        }
        if (depth >= MAX_DEPTH) {
            return JsonNodeFactory.instance.textNode("[DEPTH_LIMIT]");
        }
        if (node.isObject()) {
            ObjectNode sanitized = JsonNodeFactory.instance.objectNode();
            node.fields().forEachRemaining(entry -> {
                if (isSensitiveField(entry.getKey())) {
                    sanitized.put(entry.getKey(), "[REDACTED]");
                } else {
                    sanitized.set(entry.getKey(), sanitize(entry.getValue(), depth + 1));
                }
            });
            return sanitized;
        }
        if (node.isArray()) {
            ArrayNode sanitized = JsonNodeFactory.instance.arrayNode();
            int limit = Math.min(node.size(), MAX_ARRAY_ITEMS);
            for (int index = 0; index < limit; index++) {
                sanitized.add(sanitize(node.get(index), depth + 1));
            }
            if (node.size() > MAX_ARRAY_ITEMS) {
                ObjectNode marker = JsonNodeFactory.instance.objectNode();
                marker.put("truncatedItems", node.size() - MAX_ARRAY_ITEMS);
                sanitized.add(marker);
            }
            return sanitized;
        }
        if (node.isTextual() && node.textValue().length() > MAX_TEXT_LENGTH) {
            return JsonNodeFactory.instance.textNode(
                    node.textValue().substring(0, MAX_TEXT_LENGTH) + "…[TRUNCATED]"
            );
        }
        return node.deepCopy();
    }

    private static boolean isSensitiveField(String fieldName) {
        String normalized = fieldName.toLowerCase(Locale.ROOT);
        return SENSITIVE_FIELD_PARTS.stream().anyMatch(normalized::contains);
    }

    private static String requireText(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(fieldName + " must not be blank.");
        }
        return value.trim();
    }

    private static String normalizeOptional(String value, int maxLength) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String normalized = value.trim();
        return normalized.length() <= maxLength
                ? normalized
                : normalized.substring(0, maxLength);
    }

    private static String normalizeActorValue(String value, String fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        String normalized = value.trim();
        return normalized.length() <= 200
                ? normalized
                : normalized.substring(0, 200);
    }

    private record Actor(
            String subject,
            String username,
            List<String> roles
    ) {
        private Actor {
            roles = List.copyOf(new ArrayList<>(roles));
        }
    }
}
