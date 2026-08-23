package dev.cinnamonandclay.cafe.media;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;

import org.springframework.stereotype.Component;

@Component
class MediaObjectKeyFactory {

    String create(MediaPurpose purpose, String extension) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        return "media/"
                + purpose.objectPrefix()
                + "/"
                + today.getYear()
                + "/"
                + "%02d".formatted(today.getMonthValue())
                + "/"
                + UUID.randomUUID()
                + "."
                + extension;
    }
}
