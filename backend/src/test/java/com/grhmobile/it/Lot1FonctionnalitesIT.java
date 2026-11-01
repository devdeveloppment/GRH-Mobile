package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;
import com.grhmobile.service.AlertesAutomatiquesService;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;

/** Fonctionnalités du lot 1, vérifiées sur l'API réelle. */
class Lot1FonctionnalitesIT extends AbstractIntegrationTest {

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    AlertesAutomatiquesService alertes;

    private String body(Object o) throws Exception {
        return objectMapper.writeValueAsString(o);
    }

    private JsonNode getJson(String url, String token) throws Exception {
        return json(mvc.perform(get(url).header("Authorization", token)).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
    }

    private void setParam(String token, String cle, String valeur) throws Exception {
        mvc.perform(put("/api/parametres-rh/" + cle).header("Authorization", token)
                .contentType(MediaType.APPLICATION_JSON).content(body(java.util.Collections.singletonMap("valeur", valeur))))
            .andExpect(status().isNoContent());
    }

    // ── Paie : aucun taux par défaut, conformité seulement avec paramètres validés ──

    @Test
    void paieSansParametresEstUneSimulationNonConforme() throws Exception {
        String admin = bearer(ADMIN);
        mvc.perform(post("/api/paie/calculate").header("Authorization", admin).contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("month", 3, "year", 2026)))).andExpect(status().is2xxSuccessful());
        JsonNode items = getJson("/api/paie?month=3&year=2026", admin).get("items");
        assertThat(items.size()).isGreaterThan(0);
        for (JsonNode f : items) {
            assertThat(f.get("cotisations").asDouble()).isZero();
            assertThat(f.get("impots").asDouble()).isZero();
            assertThat(f.get("salaireNet").asDouble()).isEqualTo(f.get("salaireBrut").asDouble());
            assertThat(f.get("conformeReglementation").asBoolean()).isFalse();
            assertThat(f.get("avertissement").asText()).contains("SIMULATION");
        }
        long ficheId = items.get(0).get("id").asLong();
        JsonNode lignes = getJson("/api/paie/" + ficheId + "/lignes", admin).get("items");
        assertThat(lignes.get(0).get("code").asText()).isEqualTo("SALAIRE_BASE");
    }

    @Test
    void retenueAvecParametreValideRendLeBulletinConforme() throws Exception {
        String admin = bearer(ADMIN);
        // Taux FICTIF de test, sans valeur réglementaire.
        JsonNode p = json(mvc.perform(post("/api/paie/parametres").header("Authorization", admin)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("code", "TEST_TAUX", "libelle", "Taux fictif de test", "valeur", "0.10",
                    "dateDebut", "2020-01-01"))))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        assertThat(p.get("valide").asBoolean()).isFalse();

        mvc.perform(post("/api/paie/rubriques").header("Authorization", admin).contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("code", "TEST_RETENUE", "libelle", "Retenue fictive", "type", "COTISATION_SALARIALE",
                    "ordre", 100, "formule", "BRUT * TEST_TAUX"))))
            .andExpect(status().isCreated());

        // Formule invalide refusée.
        mvc.perform(post("/api/paie/rubriques").header("Authorization", admin).contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("code", "TEST_KO", "libelle", "KO", "type", "GAIN", "ordre", 5, "formule", "BRUT *"))))
            .andExpect(status().isBadRequest());

        try {
            mvc.perform(post("/api/paie/calculate").header("Authorization", admin).contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("month", 4, "year", 2026)))).andExpect(status().is2xxSuccessful());
            JsonNode f = getJson("/api/paie?month=4&year=2026", admin).get("items").get(0);
            assertThat(f.get("cotisations").asDouble()).isEqualTo(Math.round(f.get("salaireBrut").asDouble() * 0.10 * 100) / 100.0);
            assertThat(f.get("conformeReglementation").asBoolean()).as("paramètre non validé").isFalse();

            mvc.perform(put("/api/paie/parametres/" + p.get("id").asLong() + "/validation").header("Authorization", admin)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(body(Map.of("source", "Source fictive de test", "validePar", "Validateur de test"))))
                .andExpect(status().isOk());
            mvc.perform(post("/api/paie/calculate").header("Authorization", admin).contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("month", 5, "year", 2026)))).andExpect(status().is2xxSuccessful());
            JsonNode g = getJson("/api/paie?month=5&year=2026", admin).get("items").get(0);
            assertThat(g.get("conformeReglementation").asBoolean()).isTrue();
        } finally {
            jdbc.update("UPDATE rubriques_paie SET actif = false WHERE code = 'TEST_RETENUE'");
        }
    }

    @Test
    void configurationPaieInterditeAuxEmployes() throws Exception {
        mvc.perform(get("/api/paie/rubriques").header("Authorization", bearer(EMPLOYEE))).andExpect(status().isForbidden());
        mvc.perform(get("/api/paie/parametres").header("Authorization", bearer(DIRECTION))).andExpect(status().isForbidden());
    }

    // ── Calendrier et décompte des congés ──

    @Test
    void decompteOuvresExclutWeekEndEtFeries() throws Exception {
        String admin = bearer(ADMIN);
        LocalDate lundi = LocalDate.now().plusYears(1).with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));
        LocalDate dimanche = lundi.plusDays(6);
        JsonNode cal = getJson("/api/conges/decompte?debut=" + lundi + "&fin=" + dimanche, admin);
        assertThat(cal.get("jours").asInt()).as("calendaires par défaut").isEqualTo(7);

        long ferieId = json(mvc.perform(post("/api/jours-feries").header("Authorization", admin)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body(Map.of("date", lundi.plusDays(2).toString(), "libelle", "Jour férié de test"))))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString()).get("id").asLong();
        try {
            setParam(admin, "CONGES_MODE_DECOMPTE", "OUVRES");
            assertThat(getJson("/api/conges/decompte?debut=" + lundi + "&fin=" + dimanche, admin).get("jours").asInt())
                .isEqualTo(4);
            setParam(admin, "CONGES_MODE_DECOMPTE", "OUVRABLES");
            assertThat(getJson("/api/conges/decompte?debut=" + lundi + "&fin=" + dimanche, admin).get("jours").asInt())
                .isEqualTo(5);
        } finally {
            setParam(admin, "CONGES_MODE_DECOMPTE", "CALENDAIRES");
            mvc.perform(delete("/api/jours-feries/" + ferieId).header("Authorization", admin)).andExpect(status().isNoContent());
        }
        // Lecture du calendrier ouverte à l'employé, écriture interdite.
        mvc.perform(get("/api/jours-feries").header("Authorization", bearer(EMPLOYEE))).andExpect(status().isOk());
        mvc.perform(post("/api/jours-feries").header("Authorization", bearer(EMPLOYEE)).contentType(MediaType.APPLICATION_JSON)
            .content(body(Map.of("date", "2030-01-01", "libelle", "x")))).andExpect(status().isForbidden());
        mvc.perform(put("/api/parametres-rh/CONGES_MODE_DECOMPTE").header("Authorization", bearer(RH))
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("valeur", "OUVRES")))).andExpect(status().isForbidden());
    }

    @Test
    void parametreInvalideRefuse() throws Exception {
        mvc.perform(put("/api/parametres-rh/CONGES_MODE_DECOMPTE").header("Authorization", bearer(ADMIN))
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("valeur", "N_IMPORTE_QUOI"))))
            .andExpect(status().isBadRequest());
        mvc.perform(put("/api/parametres-rh/HEURES_JOUR_NORMALES").header("Authorization", bearer(ADMIN))
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("valeur", "-3"))))
            .andExpect(status().isBadRequest());
    }

    // ── Acquisition des congés ──

    @Test
    void acquisitionDesactiveeTantQueNonParametree() throws Exception {
        String admin = bearer(ADMIN);
        JsonNode r = json(mvc.perform(post("/api/conges/acquisitions?month=1&year=2026").header("Authorization", admin))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertThat(r.get("active").asBoolean()).isFalse();

        setParam(admin, "CONGES_ACQUISITION_JOURS_PAR_MOIS", "2");
        try {
            JsonNode a = json(mvc.perform(post("/api/conges/acquisitions?month=2&year=2026").header("Authorization", admin))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
            assertThat(a.get("employes").asInt()).isGreaterThan(0);
            JsonNode b = json(mvc.perform(post("/api/conges/acquisitions?month=2&year=2026").header("Authorization", admin))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
            assertThat(b.get("employes").asInt()).as("idempotent").isZero();
        } finally {
            setParam(admin, "CONGES_ACQUISITION_JOURS_PAR_MOIS", null);
        }
    }

    // ── Heures supplémentaires ──

    @Test
    void heuresSupplementairesSelonDureeNormale() throws Exception {
        String admin = bearer(ADMIN);
        LocalDate jour = LocalDate.of(2025, 6, 10);
        Long employeId = jdbc.queryForObject("SELECT id FROM employes WHERE matricule = 'GRH-KM-240421-002'", Long.class);
        jdbc.update("INSERT INTO presences (employe_id, date, heure_arrivee, heure_depart, statut, created_at) "
            + "VALUES (?, ?, ?, ?, 'PRESENT', now())", employeId, jour,
            LocalDateTime.of(jour, java.time.LocalTime.of(8, 0)), LocalDateTime.of(jour, java.time.LocalTime.of(18, 30)));

        JsonNode off = getJson("/api/presences/heures-supplementaires?debut=" + jour + "&fin=" + jour, admin);
        assertThat(off.get("configure").asBoolean()).isFalse();

        setParam(admin, "HEURES_JOUR_NORMALES", "8");
        try {
            JsonNode on = getJson("/api/presences/heures-supplementaires?debut=" + jour + "&fin=" + jour, admin);
            assertThat(on.get("items").get(0).get("heuresSupplementaires").asDouble()).isEqualTo(2.5);
        } finally {
            setParam(admin, "HEURES_JOUR_NORMALES", null);
        }
        mvc.perform(get("/api/presences/heures-supplementaires?debut=" + jour + "&fin=" + jour)
            .header("Authorization", bearer(EMPLOYEE))).andExpect(status().isForbidden());
    }

    // ── Notes de frais ──

    @Test
    void circuitNoteDeFrais() throws Exception {
        String employee = bearer(EMPLOYEE);
        MockMultipartFile pdf = new MockMultipartFile("justificatif", "recu.pdf", "application/pdf",
            "%PDF-1.4\n% justificatif de test\n".getBytes());
        JsonNode n = json(mvc.perform(multipart("/api/notes-frais").file(pdf).header("Authorization", employee)
                .param("dateDepense", LocalDate.now().minusDays(1).toString()).param("categorie", "TRANSPORT")
                .param("montant", "15000").param("description", "Taxi client (test)"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        long id = n.get("id").asLong();
        assertThat(n.get("statut").asText()).isEqualTo("SOUMISE");
        assertThat(n.get("justificatif").asBoolean()).isTrue();

        // Un faux PDF (contenu non conforme) est refusé.
        MockMultipartFile fake = new MockMultipartFile("justificatif", "virus.pdf", "application/pdf", "MZ executable".getBytes());
        mvc.perform(multipart("/api/notes-frais").file(fake).header("Authorization", employee)
                .param("dateDepense", LocalDate.now().toString()).param("categorie", "REPAS")
                .param("montant", "5000").param("description", "test"))
            .andExpect(status().isBadRequest());

        // L'employé ne peut ni lister toutes les notes ni décider.
        mvc.perform(get("/api/notes-frais").header("Authorization", employee)).andExpect(status().isForbidden());
        mvc.perform(post("/api/notes-frais/" + id + "/approve").header("Authorization", employee)).andExpect(status().isForbidden());
        // La direction (sans droit paie/congés) non plus, ni lire le justificatif.
        mvc.perform(get("/api/notes-frais/" + id + "/justificatif").header("Authorization", bearer(DIRECTION)))
            .andExpect(status().isForbidden());

        String rh = bearer(RH);
        mvc.perform(post("/api/notes-frais/" + id + "/remboursement").header("Authorization", rh)
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("reference", "VIR-1"))))
            .andExpect(status().isBadRequest()); // pas encore approuvée
        mvc.perform(post("/api/notes-frais/" + id + "/approve").header("Authorization", rh)).andExpect(status().isOk());
        mvc.perform(post("/api/notes-frais/" + id + "/remboursement").header("Authorization", rh)
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("reference", ""))))
            .andExpect(status().isBadRequest()); // référence obligatoire
        mvc.perform(post("/api/notes-frais/" + id + "/remboursement").header("Authorization", rh)
            .contentType(MediaType.APPLICATION_JSON).content(body(Map.of("reference", "VIR-TEST-001"))))
            .andExpect(status().isOk());

        JsonNode mine = getJson("/api/notes-frais/me", employee);
        boolean rembourse = false;
        for (JsonNode it : mine.get("items")) {
            if (it.get("id").asLong() == id) rembourse = "REMBOURSEE".equals(it.get("statut").asText());
        }
        assertThat(rembourse).isTrue();
        mvc.perform(get("/api/notes-frais/" + id + "/justificatif").header("Authorization", employee)).andExpect(status().isOk());
    }

    // ── Arrivée / départ ──

    @Test
    void listeArriveeGenereeEtCochee() throws Exception {
        String rh = bearer(RH);
        String matricule = "GRH-YL-240421-003";
        JsonNode l = json(mvc.perform(post("/api/employees/" + matricule + "/integration/arrivee").header("Authorization", rh))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        assertThat(l.get("total").asInt()).isGreaterThan(0);
        mvc.perform(post("/api/employees/" + matricule + "/integration/arrivee").header("Authorization", rh))
            .andExpect(status().isBadRequest()); // pas de doublon
        long tache = l.get("items").get(0).get("id").asLong();
        mvc.perform(put("/api/integration/taches/" + tache).header("Authorization", rh).contentType(MediaType.APPLICATION_JSON)
            .content(body(Map.of("faite", true)))).andExpect(status().isOk());
        assertThat(getJson("/api/employees/" + matricule + "/integration", rh).get("faites").asInt()).isEqualTo(1);
        mvc.perform(get("/api/employees/" + matricule + "/integration").header("Authorization", bearer(EMPLOYEE)))
            .andExpect(status().isForbidden());
    }

    // ── Alertes automatiques ──

    @Test
    void alerteContratEnvoyeeUneSeuleFois() throws Exception {
        Map<String, Object> first = alertes.alerterContratsExpirant(LocalDate.now());
        Map<String, Object> second = alertes.alerterContratsExpirant(LocalDate.now());
        assertThat((Integer) first.get("contratsConcernes")).isGreaterThan(0);
        assertThat((Integer) second.get("nouvellesAlertes")).isZero();
    }
}
