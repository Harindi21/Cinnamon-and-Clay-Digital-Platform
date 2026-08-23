package dev.cinnamonandclay.cafe.audit;

import java.time.Instant;
import java.util.UUID;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

@RestController
@Validated
@RequestMapping("/api/v1/admin/audit")
class AdminAuditController {

    private final AuditQueryService queryService;

    AdminAuditController(AuditQueryService queryService) {
        this.queryService = queryService;
    }

    @GetMapping
    AuditQueryService.AuditPage find(
            @RequestParam(required = false) @Size(max = 200) String actor,
            @RequestParam(required = false) @Size(max = 80) String action,
            @RequestParam(required = false) @Size(max = 120) String resourceType,
            @RequestParam(required = false) @Size(max = 200) String resourceId,
            @RequestParam(required = false) @Size(max = 80) String requestId,
            @RequestParam(required = false) @Size(max = 64) String traceId,
            @RequestParam(required = false) Instant from,
            @RequestParam(required = false) Instant to,
            @RequestParam(required = false) @Size(max = 512) String cursor,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit
    ) {
        return queryService.find(
                new AuditQueryService.AuditFilter(
                        actor,
                        action,
                        resourceType,
                        resourceId,
                        requestId,
                        traceId,
                        from,
                        to,
                        cursor,
                        limit
                )
        );
    }

    @GetMapping("/{id}")
    AuditQueryService.AuditEvent get(@PathVariable UUID id) {
        return queryService.requireById(id);
    }
}
