package dev.cinnamonandclay.cafe.media;

import java.io.InputStream;

import org.springframework.stereotype.Component;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Component
class S3MediaStorage implements MediaStorage {

    private final S3Client s3Client;
    private final MediaProperties properties;

S3MediaStorage(
        S3Client s3Client,
        MediaProperties properties
) {
    this.s3Client = s3Client;
    this.properties = properties;
}
    @Override
    public void store(
            String objectKey,
            InputStream content,
            long contentLength,
            String contentType
    ) {
        var request = PutObjectRequest.builder()
                .bucket(properties.bucket())
                .key(objectKey)
                .contentType(contentType)
                .build();

        s3Client.putObject(
                request,
                RequestBody.fromInputStream(content, contentLength)
        );
    }

    @Override
public InputStream open(String objectKey) {
    var request = GetObjectRequest.builder()
            .bucket(properties.bucket())
            .key(objectKey)
            .build();

    return s3Client.getObject(request);
}

    @Override
    public void delete(String objectKey) {
        var request = DeleteObjectRequest.builder()
                .bucket(properties.bucket())
                .key(objectKey)
                .build();

        s3Client.deleteObject(request);
    }

}