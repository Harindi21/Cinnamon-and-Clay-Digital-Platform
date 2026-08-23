package dev.cinnamonandclay.cafe.audit;

import java.util.Locale;

import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import io.micrometer.core.instrument.MeterRegistry;

@Component
class AuditMetrics {

    private final MeterRegistry meterRegistry;

    AuditMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    @TransactionalEventListener(
            phase = TransactionPhase.AFTER_COMMIT,
            fallbackExecution = true
    )
    void recordCommittedChange(AdminChangeRecordedEvent event) {
        meterRegistry.counter(
                "cafe.admin.audit.events",
                "action", event.action().name().toLowerCase(Locale.ROOT),
                "resource_type", event.resourceType()
        ).increment();
    }
}
