package dev.cinnamonandclay.cafe.audit;

public record AdminChangeRecordedEvent(
        AuditAction action,
        String resourceType,
        String resourceId
) {
}
