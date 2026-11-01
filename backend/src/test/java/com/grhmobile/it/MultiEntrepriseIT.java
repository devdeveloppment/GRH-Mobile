package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * Isolation multi-entreprise, vérifiée à deux niveaux :
 * 1. PostgreSQL (RLS) indépendamment de l'application ;
 * 2. l'API : listes, accès par identifiant, recherche native, fichiers, assistant, pages publiques.
 * Entreprise A = « defaut » (id 1), entreprise B = « demo-b » (fictive).
 */
class MultiEntrepriseIT extends AbstractIntegrationTest {

    private long idB() {
        return jdbc.queryForObject("SELECT id FROM entreprises WHERE slug = 'demo-b'", Long.class);
    }

    private String body(String url, String token) throws Exception {
        return mvc.perform(get(url).header("Authorization", token)).andReturn().getResponse()
            .getContentAsString(StandardCharsets.UTF_8);
    }

    private int code(String url, String token) throws Exception {
        return mvc.perform(get(url).header("Authorization", token)).andReturn().getResponse().getStatus();
    }

    // ── 1. Base de données : RLS ────────────────────────────────────────────

    @Test
    void rlsSansEntrepriseNeRenvoieRien() {
        // Connexion brute sans variable : fail closed.
        assertThat(jdbc.queryForObject("SELECT count(*) FROM employes", Long.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM utilisateurs", Long.class)).isZero();
    }

    @Test
    void rlsLimiteLaLectureALEntreprise() {
        long b = idB();
        Long matriculesBdansA = longEntreprise(1, "SELECT count(*) FROM employes WHERE matricule LIKE 'DEMOB-%'");
        Long matriculesAdansB = longEntreprise(b, "SELECT count(*) FROM employes WHERE matricule LIKE 'GRH-%'");
        assertThat(matriculesBdansA).isZero();
        assertThat(matriculesAdansB).isZero();
        assertThat(longEntreprise(b, "SELECT count(*) FROM employes")).isEqualTo(2L);
    }

    @Test
    void rlsInterditDEcrireDansUneAutreEntreprise() {
        long b = idB();
        assertThatThrownBy(() -> updateEntreprise(1,
            "INSERT INTO services (nom, description, actif, created_at, entreprise_id) VALUES ('Intrus', 'x', true, now(), ?)", b))
            .rootCause().hasMessageContaining("row-level security");
        // Une mise à jour ciblant B depuis A ne touche aucune ligne.
        assertThat(updateEntreprise(1, "UPDATE employes SET poste = 'pirate' WHERE matricule = 'DEMOB-001'")).isZero();
    }

    // ── 2. API ──────────────────────────────────────────────────────────────

    @Test
    void listesCloisonnees() throws Exception {
        String a = bearer(ADMIN);
        String b = bearer(ADMIN_B);
        List<String> listes = List.of("/api/employees", "/api/employees/annuaire", "/api/services", "/api/departements",
            "/api/postes", "/api/conges", "/api/presences", "/api/paie?month=1&year=2026", "/api/offres", "/api/formations",
            "/api/evaluations", "/api/admin/users", "/api/audit-logs", "/api/notifications", "/api/contrats/expirant",
            "/api/notes-frais", "/api/jours-feries", "/api/parametres-rh", "/api/paie/rubriques", "/api/paie/parametres",
            "/api/dashboard/summary", "/api/dashboard/enhanced", "/api/admin/stats", "/api/employees?q=Tossou");
        for (String url : listes) {
            String vueB = body(url, b);
            assertThat(vueB).as("B ne doit voir aucune donnée de A sur %s", url)
                .doesNotContain("GRH-AT-240421", "GRH-KM-240421", "@grh-mobile.com", "Tossou", "Mensah");
            String vueA = body(url, a);
            assertThat(vueA).as("A ne doit voir aucune donnée de B sur %s", url).doesNotContain("DEMOB-", "demo-b.example");
        }
        JsonNode employesB = json(body("/api/employees", b));
        assertThat(employesB.get("items").size()).isEqualTo(2);
    }

    @Test
    void accesParIdentifiantRefuse() throws Exception {
        String a = bearer(ADMIN);
        String b = bearer(ADMIN_B);
        assertThat(code("/api/employees/DEMOB-001", a)).isEqualTo(404);
        assertThat(code("/api/employees/GRH-AT-240421-001", b)).isEqualTo(404);
        assertThat(code("/api/employees/GRH-AT-240421-001/documents", b)).isIn(403, 404);
        assertThat(code("/api/employees/GRH-AT-240421-001/paie", b)).isIn(403, 404);
        int put = mvc.perform(put("/api/employees/GRH-AT-240421-001").header("Authorization", b)
                .contentType(MediaType.APPLICATION_JSON).content("{\"nom\":\"Pirate\"}"))
            .andReturn().getResponse().getStatus();
        assertThat(put).isIn(400, 403, 404);
        assertThat(longEntreprise(1, "SELECT count(*) FROM employes WHERE nom = 'Pirate'")).isZero();

        // Document de A téléchargé depuis B : refusé.
        Long docA = longEntreprise(1, "SELECT id FROM documents ORDER BY id LIMIT 1");
        assertThat(code("/api/documents/" + docA + "/download", b)).isIn(403, 404);
        // Conge de A décidé depuis B : refusé.
        Long congeA = longEntreprise(1, "SELECT id FROM conges WHERE statut = 'EN_ATTENTE' ORDER BY id LIMIT 1");
        if (congeA != null) {
            int approve = mvc.perform(post("/api/conges/" + congeA + "/approve").header("Authorization", b))
                .andReturn().getResponse().getStatus();
            assertThat(approve).isIn(403, 404);
            assertThat(longEntreprise(1, "SELECT count(*) FROM conges WHERE id = ? AND statut = 'EN_ATTENTE'", congeA)).isEqualTo(1L);
        }
    }

    @Test
    void outilsAssistantCloisonnes() throws Exception {
        String b = bearer(ADMIN_B);
        String r = mvc.perform(post("/api/assistant/outils/contrats_expirant").header("Authorization", b)
                .contentType(MediaType.APPLICATION_JSON).content("{\"jours\":365}"))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertThat(r).doesNotContain("GRH-");
        String m = mvc.perform(post("/api/assistant/outils/masse_salariale").header("Authorization", b)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertThat(json(m).get("resultat").get("nombreFiches").asInt()).isZero();
    }

    @Test
    void unicitesParEntreprise() throws Exception {
        // Le code « FIN » existe dans A : B peut créer le sien.
        int created = mvc.perform(post("/api/departements").header("Authorization", bearer(ADMIN_B))
                .contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"FIN\",\"nom\":\"Finance B\"}"))
            .andReturn().getResponse().getStatus();
        assertThat(created).isIn(200, 201);
        assertThat(longEntreprise(1, "SELECT count(*) FROM departements WHERE nom = 'Finance B'")).isZero();
    }

    @Test
    void pagesPubliquesParEntreprise() throws Exception {
        JsonNode defaut = json(mvc.perform(get("/api/public/offres")).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        JsonNode demoB = json(mvc.perform(get("/api/public/offres?entreprise=demo-b")).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(defaut.get("total").asInt()).isGreaterThan(0);
        assertThat(demoB.get("total").asInt()).isZero();
        JsonNode inconnue = json(mvc.perform(get("/api/public/offres?entreprise=inconnue")).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(inconnue.get("total").asInt()).as("entreprise inconnue : aucune donnée").isZero();
    }

    @Test
    void fichiersNonServisEnStatique() throws Exception {
        String a = bearer(ADMIN);
        assertThat(code("/cv/test.pdf", a)).isNotEqualTo(200);
        assertThat(code("/frais/test.pdf", a)).isNotEqualTo(200);
        assertThat(code("/documents/test.pdf", a)).isNotEqualTo(200);
    }

    // ── 3. Plateforme ───────────────────────────────────────────────────────

    @Test
    void plateformeReserveeAuSuperAdmin() throws Exception {
        assertThat(code("/api/plateforme/entreprises", bearer(ADMIN))).isEqualTo(403);
        assertThat(code("/api/plateforme/entreprises", bearer(ADMIN_B))).isEqualTo(403);
        JsonNode l = json(body("/api/plateforme/entreprises", bearer(PLATFORM)));
        assertThat(l.get("total").asInt()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void suspensionBloqueLAcces() throws Exception {
        String plateforme = bearer(PLATFORM);
        String tokenB = bearer(ADMIN_B);
        long b = idB();
        mvc.perform(put("/api/plateforme/entreprises/" + b + "/statut").header("Authorization", plateforme)
                .contentType(MediaType.APPLICATION_JSON).content("{\"statut\":\"SUSPENDUE\"}"))
            .andExpect(status().isOk());
        try {
            assertThat(code("/api/employees", tokenB)).as("jeton existant").isEqualTo(403);
            int login = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(Map.of("email", ADMIN_B, "password", DEMO_PASSWORD))))
                .andReturn().getResponse().getStatus();
            assertThat(login).isEqualTo(403);
        } finally {
            mvc.perform(put("/api/plateforme/entreprises/" + b + "/statut").header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"statut\":\"ACTIVE\"}"))
                .andExpect(status().isOk());
        }
        assertThat(code("/api/employees", bearer(ADMIN_B))).isEqualTo(200);
    }

    @Test
    void creationEntrepriseInitialiseSesDonnees() throws Exception {
        String plateforme = bearer(PLATFORM);
        JsonNode e = json(mvc.perform(post("/api/plateforme/entreprises").header("Authorization", plateforme)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("nom", "Test C", "slug", "test-c",
                    "adminEmail", "admin@test-c.example"))))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        long c = e.get("id").asLong();
        assertThat(e.get("motDePasseTemporaire").asText()).isNotBlank();
        assertThat(longEntreprise(c, "SELECT count(*) FROM parametres_rh")).isEqualTo(3L);
        assertThat(longEntreprise(c, "SELECT count(*) FROM rubriques_paie")).isEqualTo(1L);
        assertThat(longEntreprise(c, "SELECT count(*) FROM utilisateurs WHERE role = 'ADMIN'")).isEqualTo(1L);
        // E-mail déjà utilisé dans une autre entreprise : refusé (D2).
        mvc.perform(post("/api/plateforme/entreprises").header("Authorization", plateforme)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("nom", "Doublon", "slug", "doublon", "adminEmail", ADMIN))))
            .andExpect(status().isBadRequest());
    }
}
