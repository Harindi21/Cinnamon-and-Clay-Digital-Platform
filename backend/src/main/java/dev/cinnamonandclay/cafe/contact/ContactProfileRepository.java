// ContactProfileRepository.java
package dev.cinnamonandclay.cafe.contact;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

interface ContactProfileRepository
        extends JpaRepository<ContactProfileEntity, UUID> {
}