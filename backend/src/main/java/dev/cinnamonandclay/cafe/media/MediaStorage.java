package dev.cinnamonandclay.cafe.media;

import java.io.InputStream;

interface MediaStorage {

    void store(
            String objectKey,
            InputStream content,
            long contentLength,
            String contentType
    );

    InputStream open(String objectKey);

    void delete(String objectKey);
}