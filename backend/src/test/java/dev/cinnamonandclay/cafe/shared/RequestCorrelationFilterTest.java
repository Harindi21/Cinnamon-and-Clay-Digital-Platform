package dev.cinnamonandclay.cafe.shared;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RequestCorrelationFilterTest {

    @Test
    void preservesSafeCallerSuppliedRequestIds() {
        assertThat(RequestCorrelationFilter.resolveRequestId("admin-12345678"))
                .isEqualTo("admin-12345678");
    }

    @Test
    void replacesMissingOrUnsafeRequestIds() {
        assertThat(RequestCorrelationFilter.resolveRequestId(null))
                .matches("[0-9a-f-]{36}");
        assertThat(RequestCorrelationFilter.resolveRequestId("bad id with spaces"))
                .matches("[0-9a-f-]{36}");
        assertThat(RequestCorrelationFilter.resolveRequestId("short"))
                .matches("[0-9a-f-]{36}");
    }
}
