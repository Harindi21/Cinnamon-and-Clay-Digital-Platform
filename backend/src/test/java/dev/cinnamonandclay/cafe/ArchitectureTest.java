package dev.cinnamonandclay.cafe;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

class ArchitectureTest {

    @Test
    void modulesAreAcyclicAndRespectDeclaredBoundaries() {
        ApplicationModules.of(CafeApiApplication.class).verify();
    }
}
