package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.context.TestPropertySource;

/** Limitation du nombre de requêtes, activée uniquement pour cette classe. */
@TestPropertySource(properties = "app.securite.limitation.active=true")
class LimitationRequetesIT extends AbstractIntegrationTest {

    private MockHttpServletResponse connexion(String email, String ip) throws Exception {
        return mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("email", email, "password", "mauvais-mot-de-passe")))
                .with(r -> {
                    r.setRemoteAddr(ip);
                    return r;
                }))
            .andReturn().getResponse();
    }

    @Test
    void limitesDeConnexionParCompteEtParAdresse() throws Exception {
        // Par compte : changer d'adresse IP à chaque essai ne contourne pas la limite.
        String compte = "cible-" + UUID.randomUUID().toString().substring(0, 8) + "@exemple.test";
        for (int i = 1; i <= 10; i++) {
            assertThat(connexion(compte, "10.1.0." + i).getStatus()).as("essai %d", i).isEqualTo(401);
        }
        MockHttpServletResponse bloque = connexion(compte, "10.1.0.99");
        assertThat(bloque.getStatus()).isEqualTo(429);
        assertThat(Long.parseLong(bloque.getHeader("Retry-After"))).isBetween(1L, 900L);

        // Par adresse : 20 essais sur des comptes différents, puis refus.
        String ip = "10.2." + (int) (Math.random() * 250) + ".7";
        int premierRefus = -1;
        for (int i = 1; i <= 25 && premierRefus < 0; i++) {
            if (connexion("x" + UUID.randomUUID() + "@exemple.test", ip).getStatus() == 429) {
                premierRefus = i;
            }
        }
        assertThat(premierRefus).isEqualTo(21);
    }

    @Test
    void pagesPubliquesLimiteesParAdresse() throws Exception {
        String ip = "10.3." + (int) (Math.random() * 250) + ".8";
        int refus = 0;
        for (int i = 0; i < 125; i++) {
            int s = mvc.perform(get("/api/public/offres").param("entreprise", "defaut").with(r -> {
                r.setRemoteAddr(ip);
                return r;
            })).andReturn().getResponse().getStatus();
            if (s == 429) {
                refus++;
            }
        }
        // 120 par minute : au moins les dernières sont refusées (la fenêtre peut basculer pendant le test).
        assertThat(refus).isGreaterThan(0);
    }
}
