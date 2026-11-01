package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.http.MediaType;

/** Matrice des droits par rôle, vérifiée sur l'API réelle. */
class RolePermissionsIT extends AbstractIntegrationTest {

    @ParameterizedTest(name = "{0} GET {1} -> {2}")
    @CsvSource({
        // Administration : ADMIN seulement
        "admin@grh-mobile.com,     /api/admin/users,              200",
        "rh@grh-mobile.com,        /api/admin/users,              403",
        "employee@grh-mobile.com,  /api/admin/users,              403",
        "direction@grh-mobile.com, /api/admin/users,              403",
        "admin@grh-mobile.com,     /api/audit-logs,               200",
        "rh@grh-mobile.com,        /api/audit-logs,               403",
        // Liste du personnel : pas pour l'employé
        "admin@grh-mobile.com,     /api/employees,                200",
        "rh@grh-mobile.com,        /api/employees,                200",
        "direction@grh-mobile.com, /api/employees,                200",
        "employee@grh-mobile.com,  /api/employees,                403",
        // Paie globale : pas pour l'employé ni la direction
        "admin@grh-mobile.com,     /api/paie?month=1&year=2026,   200",
        "rh@grh-mobile.com,        /api/paie?month=1&year=2026,   200",
        "employee@grh-mobile.com,  /api/paie?month=1&year=2026,   403",
        "direction@grh-mobile.com, /api/paie?month=1&year=2026,   403",
        // Espace personnel
        "employee@grh-mobile.com,  /api/employees/me,             200",
        "employee@grh-mobile.com,  /api/paie/me,                  200",
        "employee@grh-mobile.com,  /api/conges/me,                200",
        "employee@grh-mobile.com,  /api/employees/me/evaluations, 200",
        "employee@grh-mobile.com,  /api/employees/me/documents,   200",
        "employee@grh-mobile.com,  /api/presences,                403",
        "employee@grh-mobile.com,  /api/contrats/expirant,        403",
    })
    void accessMatrix(String email, String url, int expected) throws Exception {
        int actual = mvc.perform(get(url.trim()).header("Authorization", bearer(email.trim())))
            .andReturn().getResponse().getStatus();
        assertThat(actual).as("%s GET %s", email, url).isEqualTo(expected);
    }

    @Test
    void anonymousIsRejectedOnPrivateEndpoints() throws Exception {
        for (String url : new String[] {"/api/employees", "/api/paie/me", "/api/admin/users", "/api/documents/1/download"}) {
            int code = mvc.perform(get(url)).andReturn().getResponse().getStatus();
            assertThat(code).as("anonyme GET %s", url).isIn(401, 403);
        }
    }

    @Test
    void publicJobOffersAreReadableWithoutToken() throws Exception {
        mvc.perform(get("/api/public/offres")).andExpect(status().isOk());
    }

    @Test
    void wrongPasswordIsRejected() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("email", ADMIN, "password", "mauvais-mot-de-passe"))))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void forgedTokenIsRejected() throws Exception {
        int code = mvc.perform(get("/api/employees").header("Authorization", "Bearer eyJhbGciOiJIUzI1NiJ9.e30.invalid"))
            .andReturn().getResponse().getStatus();
        assertThat(code).isIn(401, 403);
    }

    /** Non-régression : erreur 500 PostgreSQL sur les filtres nuls de l'audit. */
    @Test
    void auditSearchWithAndWithoutFilters() throws Exception {
        String token = bearer(ADMIN);
        mvc.perform(get("/api/audit-logs").header("Authorization", token)).andExpect(status().isOk());
        mvc.perform(get("/api/audit-logs?acteur=admin&action=LOGIN").header("Authorization", token))
            .andExpect(status().isOk());
    }
}
