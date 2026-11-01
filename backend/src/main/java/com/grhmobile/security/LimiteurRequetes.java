package com.grhmobile.security;

import java.sql.Timestamp;
import java.time.Instant;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/**
 * Limitation du nombre de requêtes par fenêtre fixe. Les compteurs sont dans PostgreSQL :
 * ils sont donc partagés par toutes les instances de l'API (pas de contournement en répartissant
 * les requêtes entre instances) et l'incrément est atomique (INSERT … ON CONFLICT … RETURNING).
 */
@Service
public class LimiteurRequetes {

    private final JdbcTemplate jdbcTemplate;

    public LimiteurRequetes(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Incrémente le compteur de {@code cle} et indique si la limite est dépassée.
     *
     * @return le nombre de secondes avant la fin de la fenêtre si la limite est dépassée, sinon 0
     */
    public long consommer(String cle, int limite, int fenetreSecondes) {
        long maintenant = Instant.now().getEpochSecond();
        long debut = maintenant - (maintenant % fenetreSecondes);
        Integer compteur = jdbcTemplate.queryForObject(
            "INSERT INTO limites_requetes (cle, fenetre_debut, compteur) VALUES (?, ?, 1) "
                + "ON CONFLICT (cle, fenetre_debut) DO UPDATE SET compteur = limites_requetes.compteur + 1 "
                + "RETURNING compteur",
            Integer.class, tronquer(cle), Timestamp.from(Instant.ofEpochSecond(debut)));
        if (compteur != null && compteur > limite) {
            return Math.max(1, debut + fenetreSecondes - maintenant);
        }
        return 0;
    }

    private static String tronquer(String cle) {
        return cle.length() > 200 ? cle.substring(0, 200) : cle;
    }
}
