package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/** Circuit réel d'une demande de congé : soumission, droits de décision, approbation. */
class CongeWorkflowIT extends AbstractIntegrationTest {

    @Test
    void employeeSubmitsAndRhApproves() throws Exception {
        String employee = bearer(EMPLOYEE);
        LocalDate monday = LocalDate.now().plusWeeks(6).with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));

        String created = mvc.perform(post("/api/conges").header("Authorization", employee)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of(
                    "typeConge", "ANNUEL",
                    "dateDebut", monday.toString(),
                    "dateFin", monday.plusDays(1).toString(),
                    "motif", "Test d'intégration"))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        long id = json(created).get("id").asLong();

        // L'employé ne peut pas décider de sa propre demande.
        mvc.perform(post("/api/conges/" + id + "/approve").header("Authorization", employee))
            .andExpect(status().isForbidden());

        // Le RH approuve.
        mvc.perform(post("/api/conges/" + id + "/approve").header("Authorization", bearer(RH)))
            .andExpect(status().isNoContent());

        JsonNode mine = json(mvc.perform(get("/api/conges/me").header("Authorization", employee))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        boolean approved = false;
        for (JsonNode item : mine.get("items")) {
            if (item.get("id").asLong() == id) {
                approved = "APPROUVE".equals(item.get("statut").asText());
            }
        }
        assertThat(approved).as("la demande %d doit être APPROUVE", id).isTrue();

        // L'approbation est journalisée (régression : l'audit échouait sur la colonne JSONB).
        JsonNode audit = json(mvc.perform(get("/api/audit-logs?action=APPROVE_CONGE").header("Authorization", bearer(ADMIN)))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertThat(audit.get("items").size()).as("entrée d'audit APPROVE_CONGE").isGreaterThanOrEqualTo(1);
    }

    @Test
    void invalidRequestIsRejected() throws Exception {
        mvc.perform(post("/api/conges").header("Authorization", bearer(EMPLOYEE))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"typeConge\":\"\"}"))
            .andExpect(status().isBadRequest());
    }
}
