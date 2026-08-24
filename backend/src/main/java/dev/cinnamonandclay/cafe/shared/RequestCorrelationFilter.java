package dev.cinnamonandclay.cafe.shared;

import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
class RequestCorrelationFilter extends OncePerRequestFilter {

    static final String REQUEST_ID_HEADER = "X-Request-Id";
    private static final Pattern SAFE_REQUEST_ID = Pattern.compile(
            "[A-Za-z0-9][A-Za-z0-9._:-]{7,79}"
    );
    private static final Logger log = LoggerFactory.getLogger(
            RequestCorrelationFilter.class
    );

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String requestId = resolveRequestId(request.getHeader(REQUEST_ID_HEADER));
        long startedNanos = System.nanoTime();

        MDC.put("requestId", requestId);
        response.setHeader(REQUEST_ID_HEADER, requestId);
        try {
            filterChain.doFilter(request, response);
        } finally {
            long durationMillis = (System.nanoTime() - startedNanos) / 1_000_000L;
            logRequest(request, response, durationMillis);
            MDC.remove("requestId");
        }
    }

    private void logRequest(
            HttpServletRequest request,
            HttpServletResponse response,
            long durationMillis
    ) {
        String method = request.getMethod();
        String path = request.getRequestURI();
        int status = response.getStatus();

        if (status >= 500) {
            log.atWarn()
                    .addKeyValue("http.method", method)
                    .addKeyValue("url.path", path)
                    .addKeyValue("http.status_code", status)
                    .addKeyValue("duration_ms", durationMillis)
                    .log("Request completed with server error");
            return;
        }

        if (path.startsWith("/api/v1/admin/") && !"GET".equals(method)) {
            log.atInfo()
                    .addKeyValue("http.method", method)
                    .addKeyValue("url.path", path)
                    .addKeyValue("http.status_code", status)
                    .addKeyValue("duration_ms", durationMillis)
                    .log("Administrator mutation request completed");
            return;
        }

        log.atDebug()
                .addKeyValue("http.method", method)
                .addKeyValue("url.path", path)
                .addKeyValue("http.status_code", status)
                .addKeyValue("duration_ms", durationMillis)
                .log("Request completed");
    }

    static String resolveRequestId(String supplied) {
        if (supplied != null) {
            String candidate = supplied.trim();
            if (SAFE_REQUEST_ID.matcher(candidate).matches()) {
                return candidate;
            }
        }
        return UUID.randomUUID().toString();
    }
}
