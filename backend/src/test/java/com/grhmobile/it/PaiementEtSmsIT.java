package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import com.grhmobile.integrations.paiement.FournisseurPaiement;
import com.grhmobile.integrations.paiement.PaiementService;
import com.grhmobile.integrations.sms.FournisseurSms;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;

/**
 * Paiement : fournisseur FICTIF défini uniquement dans les tests (signature HMAC-SHA256), pour vérifier
 * les règles de sécurité. Aucun fournisseur réel n'est appelé ; aucun paiement réel n'existe.
 */
@TestPropertySource(properties = "app.paiement.fournisseur=TEST_HMAC")
@Import(PaiementEtSmsIT.FournisseurTest.class)
class PaiementEtSmsIT extends AbstractIntegrationTest {

    static final String SECRET = "secret-de-test-uniquement";

    @TestConfiguration
    static class FournisseurTest {
        @Bean
        FournisseurPaiement fournisseurHmacDeTest() {
            return new FournisseurPaiement() {
                public String nom() { return "TEST_HMAC"; }
                public boolean actif() { return true; }
                public Initiation initier(String ref, BigDecimal montant, String devise, String d) {
                    return new Initiation("FICTIF-" + ref, "https://paiement.invalid/" + ref);
                }
                public boolean signatureValide(String corps, Map<String, String> entetes) {
                    return signer(corps).equals(entetes.get("x-signature"));
                }
                public Notification lireNotification(String corps) {
                    String[] p = corps.split(";");
                    return new Notification(p[0], p[1], new BigDecimal(p[2]));
                }
            };
        }
    }

    static String signer(String corps) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(corps.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    @Autowired
    FournisseurSms sms;

    @Autowired
    PaiementService paiementService;

    private String statut(String ref) {
        return jdbc.queryForObject("SELECT statut FROM transactions_paiement WHERE reference = ?", String.class, ref);
    }

    private int notifier(String corps, String signature) throws Exception {
        return mvc.perform(post("/api/paiements/notifications/TEST_HMAC").contentType(MediaType.TEXT_PLAIN)
            .content(corps).header("X-Signature", signature)).andReturn().getResponse().getStatus();
    }

    private String initier(String plateforme, String cle, String montant) throws Exception {
        String r = mvc.perform(post("/api/plateforme/paiements").header("Authorization", plateforme)
                .header("Idempotency-Key", cle).contentType(MediaType.APPLICATION_JSON)
                .content("{\"entrepriseId\":1,\"montant\":" + montant + ",\"description\":\"Abonnement fictif\"}"))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return json(r).get("reference").asText();
    }

    @Test
    void reglesDeSecuriteDuPaiement() throws Exception {
        String plateforme = bearer(PLATFORM);
        String cle = UUID.randomUUID().toString();
        String ref = initier(plateforme, cle, "10000");
        assertThat(statut(ref)).isEqualTo("EN_ATTENTE");
        assertThat(initier(plateforme, cle, "10000")).as("idempotence").isEqualTo(ref);

        // Signature fausse : refusée, statut inchangé, notification journalisée.
        String corps = ref + ";REUSSI;10000";
        assertThat(notifier(corps, "faux")).isEqualTo(401);
        assertThat(statut(ref)).isEqualTo("EN_ATTENTE");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM notifications_paiement WHERE signature_valide = false",
            Long.class)).isGreaterThan(0);

        // Signature valide : REUSSI. Rejeu d'un échec ensuite : sans effet.
        assertThat(notifier(corps, signer(corps))).isEqualTo(200);
        assertThat(statut(ref)).isEqualTo("REUSSI");
        String echec = ref + ";ECHEC;10000";
        assertThat(notifier(echec, signer(echec))).isEqualTo(200);
        assertThat(statut(ref)).isEqualTo("REUSSI");

        // Montant notifié différent du montant attendu : jamais REUSSI.
        String ref2 = initier(plateforme, UUID.randomUUID().toString(), "5000");
        String fraude = ref2 + ";REUSSI;1";
        notifier(fraude, signer(fraude));
        assertThat(statut(ref2)).isEqualTo("ECHEC");

        // Expiration des transactions en attente (tâche planifiée appelée directement).
        String ref3 = initier(plateforme, UUID.randomUUID().toString(), "5000");
        jdbc.update("UPDATE transactions_paiement SET expire_le = now() - interval '1 minute' WHERE reference = ?", ref3);
        assertThat(paiementService.expirer()).isGreaterThanOrEqualTo(1);
        assertThat(statut(ref3)).isEqualTo("EXPIRE");
        // Une notification « réussie » arrivée après expiration ne change rien.
        String tard = ref3 + ";REUSSI;5000";
        notifier(tard, signer(tard));
        assertThat(statut(ref3)).isEqualTo("EXPIRE");

        // Réservé au super-administrateur.
        assertThat(mvc.perform(get("/api/plateforme/paiements").header("Authorization", bearer(ADMIN)))
            .andReturn().getResponse().getStatus()).isEqualTo(403);
    }

    @Test
    void smsDesactiveNeSePresenteJamaisCommeEnvoye() {
        FournisseurSms.ResultatSms r = sms.envoyer("+22890000000", "Message fictif");
        assertThat(r.statut()).isEqualTo(FournisseurSms.Statut.NON_ENVOYE);
        assertThat(r.motif()).contains("désactivé");
    }
}
