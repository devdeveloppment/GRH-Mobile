package com.grhmobile;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.boot.test.context.SpringBootTest;

/** Démarrage complet : nécessite une base PostgreSQL (variable DB_URL). */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "DB_URL", matches = ".+")
class GrhMobileApplicationTests {

    @Test
    void contextLoads() {
    }
}
