package dev.cinnamonandclay.cafe.shared;

import java.net.URI;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
ProblemDetail handleNotFound(
        ResourceNotFoundException exception,
        HttpServletRequest request
) {
    ProblemDetail detail = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND,
            exception.getMessage()
    );

    detail.setTitle("Resource not found");
    detail.setType(
            URI.create("urn:cinnamon-clay:problem:not-found")
    );
    detail.setProperty("path", request.getRequestURI());

    return detail;
}

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(Exception exception, HttpServletRequest request) {
        log.error("Unexpected request failure: {} {}", request.getMethod(), request.getRequestURI(), exception);

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "The server could not complete the request."
        );
        detail.setTitle("Internal server error");
        detail.setType(URI.create("urn:cinnamon-clay:problem:internal-error"));
        detail.setProperty("path", request.getRequestURI());
        return detail;
    }
}
