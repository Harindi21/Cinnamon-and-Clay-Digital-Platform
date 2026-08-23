// SiteContentRepository.java
package dev.cinnamonandclay.cafe.content;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface SiteContentRepository extends JpaRepository<SiteContentEntity, UUID> {
}