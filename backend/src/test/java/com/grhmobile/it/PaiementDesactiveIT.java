package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/** Configuration par défaut : aucun fournisseur, paiement indisponible (503), notifications refusées. */
class PaiementDesactiveIT extends AbstractIntegrationTest {

    @Test
    void paiementDesactiveParDefaut() throws Exception {
        String plateforme = bearer(PLATFORM);
        String statut = mvc.perform(get("/api/plateforme/paiements/statut").header("Authorization", plateforme))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertThat(json(statut).get("actif").asBoolean()).isFalse();
        int initier = mvc.perform(post("/api/plateforme/paiements").header("Authorization", plateforme)
                .header("Idempotency-Key", "cle-de-test-0001").contentType(MediaType.APPLICATION_JSON)
                .content("{\"entrepriseId\":1,\"montant\":1000}"))
            .andReturn().getResponse().getStatus();
        assertThat(initier).isEqualTo(503);
        int notif = mvc.perform(post("/api/paiements/notifications/QUELCONQUE").contentType(MediaType.TEXT_PLAIN)
            .content("x;REUSSI;1000")).andReturn().getResponse().getStatus();
        assertThat(notif).isEqualTo(401);
    }
}
