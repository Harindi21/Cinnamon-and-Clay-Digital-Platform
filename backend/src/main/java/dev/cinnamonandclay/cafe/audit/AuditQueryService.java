package dev.cinnamonandclay.cafe.audit;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import dev.cinnamonandclay.cafe.shared.InvalidRequestException;
import dev.cinnamonandclay.cafe.shared.ResourceNotFoundException;

@Service
class AuditQueryService {

    private static final int MIN_PAGE_SIZE = 1;
    private static final int MAX_PAGE_SIZE = 100;

    private static final String SELECT_COLUMNS = """
            SELECT
                id,
                occurred_at,
                actor_subject,
                actor_username,
                actor_roles::text AS actor_roles,
                action,
                resource_type,
                resource_id,
                request_id,
                trace_id,
                before_state::text AS before_state,
                after_state::text AS after_state,
                metadata::text AS metadata
            FROM admin_audit_event
            """;

    private final NamedParameterJdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    AuditQueryService(
            NamedParameterJdbcTemplate jdbcTemplate,
            ObjectMapper objectMapper
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    AuditPage find(AuditFilter filter) {
        MapSqlParameterSource parameters = new MapSqlParameterSource();
        List<String> conditions = new ArrayList<>();

        if (hasText(filter.actor())) {
            conditions.add("actor_username = :actor");
            parameters.addValue("actor", filter.actor().trim());
        }
        if (hasText(filter.action())) {
            String action = normalizeAction(filter.action());
            conditions.add("action = :action");
            parameters.addValue("action", action);
        }
        if (hasText(filter.resourceType())) {
            conditions.add("resource_type = :resourceType");
            parameters.addValue("resourceType", filter.resourceType().trim());
        }
        if (hasText(filter.resourceId())) {
            conditions.add("resource_id = :resourceId");
            parameters.addValue("resourceId", filter.resourceId().trim());
        }
        if (hasText(filter.requestId())) {
            conditions.add("request_id = :requestId");
            parameters.addValue("requestId", filter.requestId().trim());
        }
        if (hasText(filter.traceId())) {
            conditions.add("trace_id = :traceId");
            parameters.addValue("traceId", filter.traceId().trim());
        }
        if (filter.from() != null) {
            conditions.add("occurred_at >= :from");
            parameters.addValue("from", toDatabaseTimestamp(filter.from()));
        }
        if (filter.to() != null) {
            conditions.add("occurred_at <= :to");
            parameters.addValue("to", toDatabaseTimestamp(filter.to()));
        }
        if (filter.from() != null && filter.to() != null
                && filter.from().isAfter(filter.to())) {
            throw new InvalidRequestException("Audit filter 'from' must be before 'to'.");
        }

        Cursor cursor = decodeCursor(filter.cursor());
        if (cursor != null) {
            conditions.add("""
                    (
                        occurred_at < :cursorOccurredAt
                        OR (occurred_at = :cursorOccurredAt AND id < :cursorId)
                    )
                    """);
            parameters.addValue(
                    "cursorOccurredAt",
                    toDatabaseTimestamp(cursor.occurredAt())
            );
            parameters.addValue("cursorId", cursor.id());
        }

        int requestedLimit = validatePageSize(filter.limit());
        long queryLimit = (long) requestedLimit + 1L;
        parameters.addValue("limit", queryLimit);

        StringBuilder sql = new StringBuilder(SELECT_COLUMNS);
        if (!conditions.isEmpty()) {
            sql.append(" WHERE ").append(String.join(" AND ", conditions));
        }
        sql.append(" ORDER BY occurred_at DESC, id DESC LIMIT :limit");

        List<AuditEvent> fetched = jdbcTemplate.query(
                sql.toString(),
                parameters,
                (rs, rowNum) -> new AuditEvent(
                        rs.getObject("id", UUID.class),
                        rs.getObject("occurred_at", java.time.OffsetDateTime.class)
                                .toInstant(),
                        rs.getString("actor_subject"),
                        rs.getString("actor_username"),
                        parseStringList(rs.getString("actor_roles")),
                        rs.getString("action"),
                        rs.getString("resource_type"),
                        rs.getString("resource_id"),
                        rs.getString("request_id"),
                        rs.getString("trace_id"),
                        parseNullableJson(rs.getString("before_state")),
                        parseNullableJson(rs.getString("after_state")),
                        parseJson(rs.getString("metadata"))
                )
        );

        boolean hasMore = fetched.size() > requestedLimit;
        List<AuditEvent> items = hasMore
                ? List.copyOf(fetched.subList(0, requestedLimit))
                : List.copyOf(fetched);
        String nextCursor = null;
        if (hasMore && !items.isEmpty()) {
            AuditEvent last = items.getLast();
            nextCursor = encodeCursor(last.occurredAt(), last.id());
        }

        return new AuditPage(items, nextCursor);
    }

    @Transactional(readOnly = true)
    AuditEvent requireById(UUID id) {
        List<AuditEvent> results = jdbcTemplate.query(
                SELECT_COLUMNS + " WHERE id = :id",
                Map.of("id", id),
                (rs, rowNum) -> new AuditEvent(
                        rs.getObject("id", UUID.class),
                        rs.getObject("occurred_at", java.time.OffsetDateTime.class)
                                .toInstant(),
                        rs.getString("actor_subject"),
                        rs.getString("actor_username"),
                        parseStringList(rs.getString("actor_roles")),
                        rs.getString("action"),
                        rs.getString("resource_type"),
                        rs.getString("resource_id"),
                        rs.getString("request_id"),
                        rs.getString("trace_id"),
                        parseNullableJson(rs.getString("before_state")),
                        parseNullableJson(rs.getString("after_state")),
                        parseJson(rs.getString("metadata"))
                )
        );
        if (results.isEmpty()) {
            throw new ResourceNotFoundException("Audit event " + id + " was not found.");
        }
        return results.getFirst();
    }

    private String normalizeAction(String value) {
        try {
            return AuditAction.valueOf(value.trim().toUpperCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException exception) {
            throw new InvalidRequestException(
                    "Unsupported audit action. Expected one of: "
                            + String.join(
                                    ", ",
                                    java.util.Arrays.stream(AuditAction.values())
                                            .map(Enum::name)
                                            .toList()
                            )
            );
        }
    }

    private Cursor decodeCursor(String encoded) {
        if (!hasText(encoded)) {
            return null;
        }
        try {
            String decoded = new String(
                    Base64.getUrlDecoder().decode(encoded.trim()),
                    StandardCharsets.UTF_8
            );
            int delimiter = decoded.lastIndexOf('|');
            if (delimiter <= 0 || delimiter == decoded.length() - 1) {
                throw new IllegalArgumentException("Malformed cursor");
            }
            return new Cursor(
                    Instant.parse(decoded.substring(0, delimiter)),
                    UUID.fromString(decoded.substring(delimiter + 1))
            );
        } catch (RuntimeException exception) {
            throw new InvalidRequestException("The audit cursor is invalid.");
        }
    }

    private static String encodeCursor(Instant occurredAt, UUID id) {
        String value = occurredAt + "|" + id;
        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }

    private List<String> parseStringList(String json) {
        try {
            return objectMapper.readerForListOf(String.class).readValue(json);
        } catch (JacksonException exception) {
            throw new IllegalStateException("Unable to read audit actor roles.", exception);
        }
    }

    private JsonNode parseNullableJson(String json) {
        return json == null ? null : parseJson(json);
    }

    private JsonNode parseJson(String json) {
        try {
            return objectMapper.readTree(json);
        } catch (JacksonException exception) {
            throw new IllegalStateException("Unable to read audit JSON.", exception);
        }
    }

    private static int validatePageSize(int limit) {
        if (limit < MIN_PAGE_SIZE || limit > MAX_PAGE_SIZE) {
            throw new InvalidRequestException(
                    "Audit page size must be between "
                            + MIN_PAGE_SIZE
                            + " and "
                            + MAX_PAGE_SIZE
                            + "."
            );
        }
        return limit;
    }

    private static OffsetDateTime toDatabaseTimestamp(Instant instant) {
        return instant.atOffset(ZoneOffset.UTC);
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    record AuditFilter(
            String actor,
            String action,
            String resourceType,
            String resourceId,
            String requestId,
            String traceId,
            Instant from,
            Instant to,
            String cursor,
            int limit
    ) {
    }

    record AuditPage(
            List<AuditEvent> items,
            String nextCursor
    ) {
    }

    record AuditEvent(
            UUID id,
            Instant occurredAt,
            String actorSubject,
            String actorUsername,
            List<String> actorRoles,
            String action,
            String resourceType,
            String resourceId,
            String requestId,
            String traceId,
            JsonNode beforeState,
            JsonNode afterState,
            JsonNode metadata
    ) {
    }

    private record Cursor(Instant occurredAt, UUID id) {
    }
}
