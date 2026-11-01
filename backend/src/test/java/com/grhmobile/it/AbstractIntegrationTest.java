package com.grhmobile.it;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
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
    "app.platform-admin.email=" + AbstractIntegrationTest.PLATFORM,
    "app.platform-admin.password=" + AbstractIntegrationTest.ADMIN_PASSWORD,
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
    /** Super-administrateur de la plateforme (gestion des entreprises). */
    static final String PLATFORM = "plateforme@grh-mobile.test";
    /** Administrateur de la seconde entreprise fictive « demo-b ». */
    static final String ADMIN_B = "admin@demo-b.example";

    /**
     * Conteneur unique pour toute la suite : le contexte Spring est mis en cache entre
     * les classes de test, il doit donc toujours pointer vers la même base.
     */
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.11-alpine");

    /** Rôle applicatif SANS superutilisateur ni BYPASSRLS : la RLS s'applique réellement. */
    static final String APP_USER = "grh_app";
    static final String APP_PASSWORD = "app-test-only";

    static {
        POSTGRES.start();
        // Le compte du conteneur est superutilisateur (il contournerait la RLS) : il ne sert qu'aux
        // migrations Flyway. L'application se connecte avec un rôle ordinaire, comme en production.
        try (java.sql.Connection c = java.sql.DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             java.sql.Statement st = c.createStatement()) {
            st.execute("CREATE ROLE " + APP_USER + " LOGIN PASSWORD '" + APP_PASSWORD + "' NOSUPERUSER NOBYPASSRLS");
            st.execute("GRANT USAGE ON SCHEMA public TO " + APP_USER);
            st.execute("ALTER DEFAULT PRIVILEGES FOR ROLE " + POSTGRES.getUsername()
                + " IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO " + APP_USER);
            st.execute("ALTER DEFAULT PRIVILEGES FOR ROLE " + POSTGRES.getUsername()
                + " IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO " + APP_USER);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException("Préparation du rôle applicatif impossible", e);
        }
    }

    @org.springframework.test.context.DynamicPropertySource
    static void datasource(org.springframework.test.context.DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", () -> APP_USER);
        registry.add("spring.datasource.password", () -> APP_PASSWORD);
        registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
        registry.add("spring.flyway.user", POSTGRES::getUsername);
        registry.add("spring.flyway.password", POSTGRES::getPassword);
    }

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected org.springframework.jdbc.core.JdbcTemplate jdbc;

    /**
     * SQL direct dans le contexte d'une entreprise (RLS) : positionne app.entreprise_id sur la
     * connexion, exécute, puis remet la variable à zéro. Sans cela, RLS ne renvoie aucune ligne.
     */
    protected <T> T sqlEntreprise(long entrepriseId,
                                  org.springframework.jdbc.core.ConnectionCallback<T> action) {
        return jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<T>) con -> {
            try (var ps = con.prepareStatement("SELECT set_config('app.entreprise_id', ?, false)")) {
                ps.setString(1, Long.toString(entrepriseId));
                ps.execute();
            }
            try {
                return action.doInConnection(con);
            } finally {
                try (var ps = con.prepareStatement("SELECT set_config('app.entreprise_id', '0', false)")) {
                    ps.execute();
                }
            }
        });
    }

    protected int updateEntreprise(long entrepriseId, String sql, Object... args) {
        return sqlEntreprise(entrepriseId, con -> {
            try (var ps = con.prepareStatement(sql)) {
                for (int i = 0; i < args.length; i++) ps.setObject(i + 1, args[i]);
                return ps.executeUpdate();
            }
        });
    }

    protected Long longEntreprise(long entrepriseId, String sql, Object... args) {
        return sqlEntreprise(entrepriseId, con -> {
            try (var ps = con.prepareStatement(sql)) {
                for (int i = 0; i < args.length; i++) ps.setObject(i + 1, args[i]);
                try (var rs = ps.executeQuery()) {
                    return rs.next() ? rs.getLong(1) : null;
                }
            }
        });
    }

    protected String login(String email) throws Exception {
        String password = ADMIN.equals(email) || PLATFORM.equals(email) ? ADMIN_PASSWORD : DEMO_PASSWORD;
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
