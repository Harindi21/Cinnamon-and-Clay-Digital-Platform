package dev.cinnamonandclay.cafe.shared;

import java.net.URI;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.ServletRequestBindingException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;

@RestControllerAdvice
class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    private static String sanitizeForLog(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace('\r', ' ')
                .replace('\n', ' ');
    }

    @ExceptionHandler(InvalidRequestException.class)
    ProblemDetail handleInvalidRequest(
            InvalidRequestException exception,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                exception.getMessage()
        );
        detail.setTitle("Invalid request");
        detail.setType(URI.create("urn:cinnamon-clay:problem:invalid-request"));
        detail.setProperty("path", request.getRequestURI());
        return withRequestContext(detail, request);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    ProblemDetail handleUploadTooLarge(
            MaxUploadSizeExceededException exception,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.PAYLOAD_TOO_LARGE,
                "The uploaded file exceeds the configured request-size limit."
        );
        detail.setTitle("Upload too large");
        detail.setType(URI.create("urn:cinnamon-clay:problem:payload-too-large"));
        detail.setProperty("path", request.getRequestURI());
        return withRequestContext(detail, request);
    }

    @ExceptionHandler({
            ServletRequestBindingException.class,
            MissingServletRequestPartException.class,
            MethodArgumentTypeMismatchException.class,
            HttpMessageNotReadableException.class
    })
    ProblemDetail handleMalformedRequest(
            Exception exception,
            HttpServletRequest request
    ) {
        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                "The request is missing a required value or contains an invalid value."
        );
        detail.setTitle("Malformed request");
        detail.setType(URI.create("urn:cinnamon-clay:problem:malformed-request"));
        detail.setProperty("path", request.getRequestURI());
        return withRequestContext(detail, request);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    ProblemDetail handleConstraintViolation(
            ConstraintViolationException exception,
            HttpServletRequest request
    ) {
        List<Map<String, String>> errors = exception.getConstraintViolations()
                .stream()
                .map(violation -> Map.of(
                        "field", violation.getPropertyPath().toString(),
                        "message", violation.getMessage()
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
        return withRequestContext(detail, request);
    }

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
        return withRequestContext(detail, request);
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
        return withRequestContext(detail, request);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ProblemDetail handleIntegrityConflict(
            DataIntegrityViolationException exception,
            HttpServletRequest request
    ) {
        String method = sanitizeForLog(request.getMethod());
        String requestUri = sanitizeForLog(request.getRequestURI());
        log.info(
                "Rejected request because a uniqueness or relational constraint was violated: {} {}",
                method,
                requestUri
        );

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT,
                "The requested change conflicts with existing data."
        );
        detail.setTitle("Data conflict");
        detail.setType(URI.create("urn:cinnamon-clay:problem:data-conflict"));
        detail.setProperty("path", request.getRequestURI());
        return withRequestContext(detail, request);
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
        return withRequestContext(detail, request);
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(
            Exception exception,
            HttpServletRequest request
    ) {
        String method = sanitizeForLog(request.getMethod());
        String requestUri = sanitizeForLog(request.getRequestURI());
        log.error(
                "Unexpected request failure: {} {}",
                method,
                requestUri,
                exception
        );

        ProblemDetail detail = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "The server could not complete the request."
        );
        detail.setTitle("Internal server error");
        detail.setType(URI.create("urn:cinnamon-clay:problem:internal-error"));
        detail.setProperty("path", request.getRequestURI());
        return withRequestContext(detail, request);
    }

    private static ProblemDetail withRequestContext(
            ProblemDetail detail,
            HttpServletRequest request
    ) {
        detail.setProperty("path", request.getRequestURI());
        String requestId = MDC.get("requestId");
        if (requestId != null && !requestId.isBlank()) {
            detail.setProperty("requestId", requestId);
        }
        String traceId = MDC.get("traceId");
        if (traceId != null && !traceId.isBlank()) {
            detail.setProperty("traceId", traceId);
        }
        return detail;
    }

}
