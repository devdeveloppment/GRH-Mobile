package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * Assistant RH sans fournisseur d'IA (aucune clé en test) : on vérifie la couche d'outils,
 * qui porte la sécurité (droits côté serveur, lecture seule, minimisation des données).
 */
class AssistantIT extends AbstractIntegrationTest {

    private List<String> outils(String email) throws Exception {
        JsonNode s = json(mvc.perform(get("/api/assistant/statut").header("Authorization", bearer(email)))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8));
        assertThat(s.get("actif").asBoolean()).as("aucune clé en test").isFalse();
        List<String> noms = new ArrayList<>();
        s.get("outils").forEach(o -> noms.add(o.get("nom").asText()));
        return noms;
    }

    private JsonNode outil(String email, String nom, Map<String, Object> input) throws Exception {
        return json(mvc.perform(post("/api/assistant/outils/" + nom).header("Authorization", bearer(email))
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(input)))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8));
    }

    @Test
    void outilsProposesSelonLeRole() throws Exception {
        assertThat(outils(EMPLOYEE)).containsExactly("solde_conges");
        assertThat(outils(DIRECTION)).contains("masse_salariale", "absents_aujourdhui")
            .doesNotContain("conges_en_attente", "contrats_expirant");
        assertThat(outils(ADMIN)).contains("contrats_expirant", "conges_en_attente", "masse_salariale",
            "absents_aujourdhui", "solde_conges");
    }

    @Test
    void droitsReverifiesCoteServeur() throws Exception {
        JsonNode r = outil(EMPLOYEE, "conges_en_attente", Map.of());
        assertThat(r.get("resultat").get("erreur").asText()).contains("Accès refusé");
        assertThat(outil(EMPLOYEE, "masse_salariale", Map.of()).get("resultat").has("erreur")).isTrue();
        // L'employé ne voit que son propre solde.
        assertThat(outil(EMPLOYEE, "solde_conges", Map.of()).get("resultat").get("matricule").asText())
            .isEqualTo("GRH-AT-240421-001");
        assertThat(outil(EMPLOYEE, "solde_conges", Map.of("matricule", "GRH-KM-240421-002")).get("resultat")
            .get("erreur").asText()).contains("Accès refusé");
        // Outil inexistant et paramètre hors limites : erreur propre, pas d'exception.
        assertThat(outil(ADMIN, "supprimer_tout", Map.of()).get("resultat").has("erreur")).isTrue();
        assertThat(outil(ADMIN, "contrats_expirant", Map.of("jours", 99999)).get("resultat").has("erreur")).isTrue();
    }

    @Test
    void donneesMinimiseesPourLeModele() throws Exception {
        JsonNode contrats = outil(ADMIN, "contrats_expirant", Map.of("jours", 60));
        assertThat(contrats.get("resultat").get("nombre").asInt()).isGreaterThan(0);
        String resultat = contrats.get("resultat").toString();
        // Le résultat (envoyé au modèle) ne contient ni nom ni salaire individuel...
        assertThat(resultat).doesNotContain("Mensah", "Tossou", "salaire");
        // ... les noms ne sont résolus que pour l'affichage, à part.
        assertThat(contrats.get("noms").toString()).contains("Mensah");

        JsonNode masse = outil(DIRECTION, "masse_salariale", Map.of()).get("resultat");
        assertThat(masse.has("totalBrut")).isTrue();
        assertThat(masse.toString()).doesNotContain("GRH-");
    }

    @Test
    void questionSansFournisseurRenvoie503() throws Exception {
        mvc.perform(post("/api/assistant/questions").header("Authorization", bearer(ADMIN))
                .contentType(MediaType.APPLICATION_JSON).content("{\"question\":\"Quels contrats expirent ?\"}"))
            .andExpect(status().isServiceUnavailable());
        mvc.perform(get("/api/assistant/statut")).andExpect(r -> assertThat(r.getResponse().getStatus()).isIn(401, 403));
    }
}
