package dev.cinnamonandclay.cafe.publishing;

import java.net.http.HttpClient;
import java.time.Duration;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(PublicCacheInvalidationProperties.class)
class PublicCacheInvalidationConfiguration {

    @Bean
    HttpClient publicCacheHttpClient() {
        return HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(500))
                .build();
    }
}
