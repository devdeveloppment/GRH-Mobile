package com.grhmobile.security;

import java.sql.Timestamp;
import java.time.Instant;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Révocation individuelle des jetons (déconnexion). La liste est en base : elle est partagée par
 * toutes les instances de l'API et survit aux redémarrages. La révocation globale d'un utilisateur
 * passe par {@code Utilisateur.revoquerSessions()} (version de session).
 */
@Service
public class RevocationJetonService {

    private static final Logger log = LoggerFactory.getLogger(RevocationJetonService.class);

    private final JdbcTemplate jdbcTemplate;

    public RevocationJetonService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void revoquer(String jti, Instant expiration) {
        if (jti == null || expiration == null) {
            return;
        }
        jdbcTemplate.update("INSERT INTO jetons_revoques (jti, expire_le) VALUES (?, ?) ON CONFLICT (jti) DO NOTHING",
            jti, Timestamp.from(expiration));
    }

    public boolean estRevoque(String jti) {
        if (jti == null) {
            return false;
        }
        Integer n = jdbcTemplate.queryForObject("SELECT count(*) FROM jetons_revoques WHERE jti = ?", Integer.class, jti);
        return n != null && n > 0;
    }

    /** Un jeton expiré est de toute façon refusé : inutile de le conserver. */
    @Scheduled(cron = "0 15 * * * *")
    public void purger() {
        int n = jdbcTemplate.update("DELETE FROM jetons_revoques WHERE expire_le < now()");
        int m = jdbcTemplate.update("DELETE FROM limites_requetes WHERE fenetre_debut < now() - interval '1 day'");
        if (n + m > 0) {
            log.info("Purge : {} jeton(s) révoqué(s) expiré(s), {} compteur(s) de limitation", n, m);
        }
    }
}
