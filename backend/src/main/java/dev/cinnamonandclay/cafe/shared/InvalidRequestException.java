package dev.cinnamonandclay.cafe.shared;

public final class InvalidRequestException extends RuntimeException {

    public InvalidRequestException(String message) {
        super(message);
    }
}
