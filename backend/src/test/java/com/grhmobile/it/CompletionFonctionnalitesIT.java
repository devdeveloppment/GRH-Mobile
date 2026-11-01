package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/** Arrivées / départs (responsables, clôture, vue d'ensemble) et fiche entreprise de la plateforme. */
class CompletionFonctionnalitesIT extends AbstractIntegrationTest {

    private JsonNode getJson(String url, String token) throws Exception {
        return json(mvc.perform(get(url).header("Authorization", token)).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private String body(Object o) throws Exception {
        return objectMapper.writeValueAsString(o);
    }

    @Test
    void departCompletAvecResponsablesEtCloture() throws Exception {
        String rh = bearer(RH);
        String matricule = sqlEntreprise(1, con -> {
            try (var rs = con.createStatement().executeQuery(
                    "SELECT e.matricule FROM employes e WHERE NOT EXISTS (SELECT 1 FROM taches_integration t "
                        + "WHERE t.employe_id = e.id AND t.type = 'DEPART') ORDER BY e.id DESC LIMIT 1")) {
                rs.next();
                return rs.getString(1);
            }
        });
        JsonNode l = json(mvc.perform(post("/api/employees/" + matricule + "/integration/depart")
                .header("Authorization", rh).contentType(MediaType.APPLICATION_JSON).content("{\"echeance\":\"2020-01-31\"}"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        long premiere = l.get("items").get(0).get("id").asLong();

        // Responsable, commentaire et échéance modifiables.
        JsonNode t = json(mvc.perform(put("/api/integration/taches/" + premiere).header("Authorization", rh)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("responsable", "Service informatique", "commentaire", "Ordinateur portable",
                    "echeance", "2020-02-15"))))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(t.get("responsable").asText()).isEqualTo("Service informatique");
        assertThat(t.get("echeance").asText()).isEqualTo("2020-02-15");

        // Vue d'ensemble : processus en retard (échéances passées).
        JsonNode processus = getJson("/api/integration/processus", rh).get("items");
        JsonNode ligne = null;
        for (JsonNode p : processus) {
            if (p.get("matricule").asText().equals(matricule) && p.get("type").asText().equals("DEPART")) {
                ligne = p;
            }
        }
        assertThat(ligne).isNotNull();
        assertThat(ligne.get("enRetard").asInt()).isGreaterThan(0);
        assertThat(ligne.get("cloture").isNull()).isTrue();

        // Clôture refusée tant que des tâches restent à faire.
        mvc.perform(post("/api/employees/" + matricule + "/integration/depart/cloture").header("Authorization", rh))
            .andExpect(status().isBadRequest());
        for (JsonNode tache : l.get("items")) {
            mvc.perform(put("/api/integration/taches/" + tache.get("id").asLong()).header("Authorization", rh)
                .contentType(MediaType.APPLICATION_JSON).content("{\"faite\":true}")).andExpect(status().isOk());
        }
        JsonNode clos = json(mvc.perform(post("/api/employees/" + matricule + "/integration/depart/cloture")
                .header("Authorization", rh).contentType(MediaType.APPLICATION_JSON)
                .content("{\"commentaire\":\"Matériel restitué\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
        assertThat(clos.get("clotures").get("DEPART").asText()).isNotBlank();
        // Processus clôturé : plus modifiable, pas de double clôture.
        mvc.perform(put("/api/integration/taches/" + premiere).header("Authorization", rh)
            .contentType(MediaType.APPLICATION_JSON).content("{\"faite\":false}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/employees/" + matricule + "/integration/depart/cloture").header("Authorization", rh))
            .andExpect(status().isBadRequest());

        // Cloisonnement : l'entreprise B ne voit pas ce processus et ne peut pas le modifier.
        String b = bearer(ADMIN_B);
        assertThat(getJson("/api/integration/processus", b).toString()).doesNotContain(matricule);
        int s = mvc.perform(put("/api/integration/taches/" + premiere).header("Authorization", b)
            .contentType(MediaType.APPLICATION_JSON).content("{\"responsable\":\"Pirate\"}")).andReturn().getResponse().getStatus();
        assertThat(s).isIn(403, 404);
        // Un employé n'a pas accès.
        mvc.perform(get("/api/integration/processus").header("Authorization", bearer(EMPLOYEE)))
            .andExpect(status().isForbidden());
    }

    @Test
    void ficheEntrepriseEtModificationParLaPlateforme() throws Exception {
        String plateforme = bearer(PLATFORM);
        long b = jdbc.queryForObject("SELECT id FROM entreprises WHERE slug = 'demo-b'", Long.class);
        JsonNode d = getJson("/api/plateforme/entreprises/" + b, plateforme);
        assertThat(d.get("slug").asText()).isEqualTo("demo-b");
        assertThat(d.get("utilisateurs").asInt()).isGreaterThan(0);
        assertThat(d.get("administrateurs").toString()).contains("admin@demo-b.example");

        String nomInitial = d.get("nom").asText();
        try {
            mvc.perform(put("/api/plateforme/entreprises/" + b).header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"nom\":\"Démo B renommée\",\"pays\":\"TG\"}"))
                .andExpect(status().isOk());
            assertThat(getJson("/api/plateforme/entreprises/" + b, plateforme).get("nom").asText()).isEqualTo("Démo B renommée");
            mvc.perform(put("/api/plateforme/entreprises/" + b).header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"slug\":\"autre\"}"))
                .andExpect(status().isBadRequest());
            mvc.perform(put("/api/plateforme/entreprises/" + b).header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"pays\":\"Togo\"}"))
                .andExpect(status().isBadRequest());

            JsonNode essai = json(mvc.perform(put("/api/plateforme/entreprises/" + b + "/offre").header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"offre\":\"ESSAI\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
            assertThat(essai.get("dateFinEssai").isNull()).isFalse();
            JsonNode pro = json(mvc.perform(put("/api/plateforme/entreprises/" + b + "/offre").header("Authorization", plateforme)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"offre\":\"PRO\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8));
            assertThat(pro.get("dateFinEssai").isNull()).isTrue();
        } finally {
            mvc.perform(put("/api/plateforme/entreprises/" + b).header("Authorization", plateforme)
                .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("nom", nomInitial))));
        }

        // Les administrateurs d'entreprise n'ont aucun accès à la plateforme.
        for (String compte : new String[]{ADMIN, ADMIN_B, RH}) {
            mvc.perform(get("/api/plateforme/entreprises/" + b).header("Authorization", bearer(compte)))
                .andExpect(status().isForbidden());
            mvc.perform(put("/api/plateforme/entreprises/" + b).header("Authorization", bearer(compte))
                    .contentType(MediaType.APPLICATION_JSON).content("{\"nom\":\"x\"}"))
                .andExpect(status().isForbidden());
        }
    }
}
