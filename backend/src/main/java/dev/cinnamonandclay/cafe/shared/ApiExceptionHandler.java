package dev.cinnamonandclay.cafe.shared;

import java.net.URI;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
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
        detail.setType(URI.create("urn:cinnamon-clay:problem:not-found"));
        detail.setProperty("path", request.getRequestURI());
        return detail;
    }

    @ExceptionHandler({
            ResourceConflictException.class,
            ObjectOptimisticLockingFailureException.class
    })
    ProblemDetail handleConflict(
            Exception exception,
            HttpServletRequest request
    ) {
        String message = exception instanceof ResourceConflictException
                ? exception.getMessage()
                : "The resource changed after it was loaded. Refresh and try again.";

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT,
                message
        );
        detail.setTitle("Resource conflict");
        detail.setType(URI.create("urn:cinnamon-clay:problem:conflict"));
        detail.setProperty("path", request.getRequestURI());
        return detail;
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ProblemDetail handleIntegrityConflict(
            DataIntegrityViolationException exception,
            HttpServletRequest request
    ) {
        log.info(
                "Rejected request because a uniqueness or relational constraint was violated: {} {}",
                request.getMethod(),
                request.getRequestURI()
        );

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT,
                "The requested change conflicts with existing data."
        );
        detail.setTitle("Data conflict");
        detail.setType(URI.create("urn:cinnamon-clay:problem:data-conflict"));
        detail.setProperty("path", request.getRequestURI());
        return detail;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail handleValidation(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        List<Map<String, String>> errors = exception
                .getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null
                                ? "Invalid value"
                                : error.getDefaultMessage()
                ))
                .toList();

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                "One or more request fields are invalid."
        );
        detail.setTitle("Validation failed");
        detail.setType(URI.create("urn:cinnamon-clay:problem:validation"));
        detail.setProperty("path", request.getRequestURI());
        detail.setProperty("errors", errors);
        return detail;
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(
            Exception exception,
            HttpServletRequest request
    ) {
        log.error(
                "Unexpected request failure: {} {}",
                request.getMethod(),
                request.getRequestURI(),
                exception
        );

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
