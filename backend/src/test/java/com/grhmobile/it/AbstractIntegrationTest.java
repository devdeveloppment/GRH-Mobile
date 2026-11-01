package com.grhmobile.it;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Base des tests d'intégration : vrai PostgreSQL (Testcontainers), migrations Flyway
 * complètes, jeu de démonstration du profil « demo ». Nécessite Docker.
 * Aucune donnée réelle : uniquement les personnes fictives du DemoDataSeeder.
 */
@SpringBootTest(properties = {
    "app.jwt.secret=test-secret-for-integration-tests-only-0123456789abcdef",
    "app.demo.password=" + AbstractIntegrationTest.DEMO_PASSWORD,
    "app.bootstrap-admin.password=" + AbstractIntegrationTest.ADMIN_PASSWORD,
    "app.upload.dir=target/test-uploads/photos",
})
@AutoConfigureMockMvc
@ActiveProfiles("demo")
public abstract class AbstractIntegrationTest {

    static final String DEMO_PASSWORD = "Demo-Test-Pass-2026!";
    static final String ADMIN_PASSWORD = "Admin-Test-Pass-2026!";

    static final String ADMIN = "admin@grh-mobile.com";
    static final String RH = "rh@grh-mobile.com";
    static final String EMPLOYEE = "employee@grh-mobile.com";
    static final String DIRECTION = "direction@grh-mobile.com";

    /**
     * Conteneur unique pour toute la suite : le contexte Spring est mis en cache entre
     * les classes de test, il doit donc toujours pointer vers la même base.
     */
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.11-alpine");

    static {
        POSTGRES.start();
    }

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected ObjectMapper objectMapper;

    protected String login(String email) throws Exception {
        String password = ADMIN.equals(email) ? ADMIN_PASSWORD : DEMO_PASSWORD;
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(java.util.Map.of("email", email, "password", password))))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).get("token").asText();
    }

    protected String bearer(String email) throws Exception {
        return "Bearer " + login(email);
    }

    protected JsonNode json(String content) throws Exception {
        return objectMapper.readTree(content);
    }
}
