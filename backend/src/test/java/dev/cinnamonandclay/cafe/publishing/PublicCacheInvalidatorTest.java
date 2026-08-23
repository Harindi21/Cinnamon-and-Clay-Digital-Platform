package dev.cinnamonandclay.cafe.publishing;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PublicCacheInvalidatorTest {

    @Test
    void mapsAdministratorResourcesToBoundedPublicCacheTags() {
        assertThat(PublicCacheInvalidator.tagsFor("catalog.item"))
                .containsExactly("catalog");
        assertThat(PublicCacheInvalidator.tagsFor("content.site"))
                .containsExactly("content");
        assertThat(PublicCacheInvalidator.tagsFor("contact.profile"))
                .containsExactly("contact");
        assertThat(PublicCacheInvalidator.tagsFor("media.asset"))
                .containsExactly("media");
        assertThat(PublicCacheInvalidator.tagsFor("reviews.review"))
                .containsExactly("reviews");
    }

    @Test
    void ignoresOperationalAuditEventsThatDoNotChangePublicContent() {
        assertThat(PublicCacheInvalidator.tagsFor("media.orphan-cleanup"))
                .isEmpty();
        assertThat(PublicCacheInvalidator.tagsFor("audit.event"))
                .isEmpty();
        assertThat(PublicCacheInvalidator.tagsFor(null))
                .isEmpty();
    }
}
