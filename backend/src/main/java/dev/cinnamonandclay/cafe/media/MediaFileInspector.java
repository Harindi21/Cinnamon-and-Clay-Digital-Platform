package dev.cinnamonandclay.cafe.media;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.Locale;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import dev.cinnamonandclay.cafe.shared.InvalidRequestException;

@Component
class MediaFileInspector {

    private final MediaUploadProperties properties;

    MediaFileInspector(MediaUploadProperties properties) {
        this.properties = properties;
    }

    InspectedMediaFile inspect(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw invalid("Choose a non-empty JPEG or PNG image.");
        }
        if (file.getSize() > properties.maxBytes()) {
            throw invalid(
                    "Image exceeds the configured upload limit of "
                            + properties.maxBytes()
                            + " bytes."
            );
        }

        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException exception) {
            throw new InvalidRequestException("The uploaded image could not be read.");
        }
        if (bytes.length > properties.maxBytes()) {
            throw invalid(
                    "Image exceeds the configured upload limit of "
                            + properties.maxBytes()
                            + " bytes."
            );
        }

        ImageMetadata metadata = imageMetadata(bytes);
        long pixels = (long) metadata.widthPixels() * metadata.heightPixels();

        if (metadata.widthPixels() > properties.maxWidth()
                || metadata.heightPixels() > properties.maxHeight()
                || pixels > properties.maxPixels()) {
            throw invalid(
                    "Image dimensions exceed the configured safety limits."
            );
        }

        return new InspectedMediaFile(
                bytes,
                sanitizeFilename(file.getOriginalFilename(), metadata.extension()),
                metadata.contentType(),
                metadata.extension(),
                metadata.widthPixels(),
                metadata.heightPixels(),
                sha256(bytes)
        );
    }

    private static ImageMetadata imageMetadata(byte[] bytes) {
        try (ImageInputStream stream = ImageIO.createImageInputStream(
                new ByteArrayInputStream(bytes)
        )) {
            if (stream == null) {
                throw invalid("The uploaded file is not a supported image.");
            }

            Iterator<ImageReader> readers = ImageIO.getImageReaders(stream);
            if (!readers.hasNext()) {
                throw invalid("The uploaded file is not a supported image.");
            }

            ImageReader reader = readers.next();
            try {
                reader.setInput(stream, true, true);
                String format = reader.getFormatName().toLowerCase(Locale.ROOT);
                String contentType;
                String extension;
                if (format.equals("jpeg") || format.equals("jpg")) {
                    contentType = "image/jpeg";
                    extension = "jpg";
                } else if (format.equals("png")) {
                    contentType = "image/png";
                    extension = "png";
                } else {
                    throw invalid("Only JPEG and PNG images are supported.");
                }

                int width = reader.getWidth(0);
                int height = reader.getHeight(0);
                if (width <= 0 || height <= 0) {
                    throw invalid("The uploaded image has invalid dimensions.");
                }
                return new ImageMetadata(
                        contentType,
                        extension,
                        width,
                        height
                );
            } finally {
                reader.dispose();
            }
        } catch (IOException exception) {
            throw invalid("The uploaded file is not a valid JPEG or PNG image.");
        }
    }

    private static String sanitizeFilename(String filename, String extension) {
        String value = filename == null ? "" : filename;
        value = value.replace('\\', '/');
        int slash = value.lastIndexOf('/');
        if (slash >= 0) {
            value = value.substring(slash + 1);
        }
        value = value.replaceAll("[\\p{Cntrl}]", "").trim();
        if (value.isBlank()) {
            value = "upload." + extension;
        }
        if (value.length() > 255) {
            value = value.substring(0, 255);
        }
        return value;
    }

    private static String sha256(byte[] bytes) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(bytes));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private static InvalidRequestException invalid(String message) {
        return new InvalidRequestException(message);
    }

    private record ImageMetadata(
            String contentType,
            String extension,
            int widthPixels,
            int heightPixels
    ) {
    }
}
