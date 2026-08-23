package dev.cinnamonandclay.cafe.media;

import java.io.InputStream;
import java.time.Instant;
import java.util.List;

interface MediaStorage {

    void store(
            String objectKey,
            InputStream content,
            long contentLength,
            String contentType
    );

    InputStream open(String objectKey);

    void delete(String objectKey);

    List<StoredObject> list(String prefix);

    record StoredObject(
            String key,
            Instant lastModified,
            long sizeBytes
    ) {
    }
}
