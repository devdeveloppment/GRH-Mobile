package com.grhmobile.integrations.paiement;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import com.grhmobile.exception.BusinessException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Paiements mobile money des abonnements SaaS. Désactivé tant qu'aucun fournisseur n'est configuré
 * ({@code app.paiement.fournisseur}). Règles :
 * <ul>
 *   <li>référence interne unique et clé d'idempotence (une même demande ne crée qu'une transaction) ;</li>
 *   <li>statut REUSSI uniquement sur notification serveur à serveur à signature vérifiée, montant égal ;</li>
 *   <li>une transaction finalisée n'est jamais modifiée (notifications rejouées sans effet) ;</li>
 *   <li>expiration automatique des transactions en attente ; toutes les notifications sont journalisées.</li>
 * </ul>
 */
@Service
public class PaiementService {

    private static final Logger log = LoggerFactory.getLogger(PaiementService.class);
    static final int MINUTES_AVANT_EXPIRATION = 30;

    private final JdbcTemplate jdbc;
    private final Optional<FournisseurPaiement> fournisseur;

    public PaiementService(JdbcTemplate jdbc, List<FournisseurPaiement> fournisseurs,
                           @Value("${app.paiement.fournisseur:}") String fournisseurConfigure) {
        this.jdbc = jdbc;
        this.fournisseur = fournisseurs.stream()
            .filter(f -> f.nom().equalsIgnoreCase(fournisseurConfigure) && f.actif()).findFirst();
    }

    public Map<String, Object> statut() {
        return Map.of("actif", fournisseur.isPresent(),
            "fournisseur", fournisseur.map(FournisseurPaiement::nom).orElse("AUCUN"),
            "message", fournisseur.isPresent() ? "Paiement disponible."
                : "Paiement désactivé : aucun fournisseur, compte marchand ni contrat configuré.");
    }

    @Transactional
    public Map<String, Object> initier(long entrepriseId, BigDecimal montant, String description, String cleIdempotence) {
        FournisseurPaiement f = fournisseur.orElseThrow(() -> new PaiementIndisponibleException());
        if (montant == null || montant.signum() <= 0) {
            throw new BusinessException("Montant invalide.");
        }
        if (cleIdempotence == null || !cleIdempotence.matches("^[A-Za-z0-9-]{8,100}$")) {
            throw new BusinessException("Clé d'idempotence obligatoire.");
        }
        List<Map<String, Object>> existante = jdbc.queryForList(
            "SELECT reference, statut, montant FROM transactions_paiement WHERE cle_idempotence = ?", cleIdempotence);
        if (!existante.isEmpty()) {
            return existante.get(0);
        }
        String reference = "GRH-" + UUID.randomUUID();
        Instant expire = Instant.now().plus(MINUTES_AVANT_EXPIRATION, ChronoUnit.MINUTES);
        jdbc.update("INSERT INTO transactions_paiement (reference, entreprise_id, fournisseur, montant, description, "
                + "cle_idempotence, expire_le) VALUES (?, ?, ?, ?, ?, ?, ?)",
            reference, entrepriseId, f.nom(), montant, description, cleIdempotence, Timestamp.from(expire));
        FournisseurPaiement.Initiation i = f.initier(reference, montant, "XOF", description);
        jdbc.update("UPDATE transactions_paiement SET reference_fournisseur = ?, updated_at = now() WHERE reference = ?",
            i.referenceFournisseur(), reference);
        return Map.of("reference", reference, "statut", "EN_ATTENTE", "urlPaiement", String.valueOf(i.urlPaiement()));
    }

    /** Notification serveur à serveur. Renvoie true si elle a été acceptée. */
    @Transactional
    public boolean notification(String nomFournisseur, String corps, Map<String, String> entetes) {
        Optional<FournisseurPaiement> f = fournisseur.filter(x -> x.nom().equalsIgnoreCase(nomFournisseur));
        boolean signature = f.isPresent() && f.get().signatureValide(corps, entetes);
        FournisseurPaiement.Notification n = null;
        if (signature) {
            try {
                n = f.get().lireNotification(corps);
            } catch (RuntimeException e) {
                signature = false;
            }
        }
        jdbc.update("INSERT INTO notifications_paiement (fournisseur, signature_valide, reference, corps) VALUES (?, ?, ?, ?)",
            nomFournisseur.length() > 40 ? nomFournisseur.substring(0, 40) : nomFournisseur, signature,
            n != null ? n.referenceInterne() : null, corps.length() > 10000 ? corps.substring(0, 10000) : corps);
        if (!signature) {
            log.warn("Notification de paiement refusée (signature invalide ou fournisseur inactif) : {}", nomFournisseur);
            return false;
        }
        List<Map<String, Object>> t = jdbc.queryForList(
            "SELECT statut, montant FROM transactions_paiement WHERE reference = ? FOR UPDATE", n.referenceInterne());
        if (t.isEmpty()) {
            log.warn("Notification pour une transaction inconnue : {}", n.referenceInterne());
            return false;
        }
        if (!"EN_ATTENTE".equals(t.get(0).get("statut"))) {
            return true; // déjà finalisée : rejeu sans effet
        }
        String statut = "REUSSI".equals(n.statut()) ? "REUSSI" : "ECHEC";
        if ("REUSSI".equals(statut) && (n.montant() == null
            || n.montant().compareTo((BigDecimal) t.get(0).get("montant")) != 0)) {
            log.warn("Montant notifié différent du montant attendu : transaction {} mise en échec", n.referenceInterne());
            statut = "ECHEC";
        }
        jdbc.update("UPDATE transactions_paiement SET statut = ?, confirme_le = now(), updated_at = now() "
            + "WHERE reference = ? AND statut = 'EN_ATTENTE'", statut, n.referenceInterne());
        return true;
    }

    @Scheduled(cron = "0 */5 * * * *")
    public int expirer() {
        return jdbc.update("UPDATE transactions_paiement SET statut = 'EXPIRE', updated_at = now() "
            + "WHERE statut = 'EN_ATTENTE' AND expire_le < now()");
    }

    public List<Map<String, Object>> transactions() {
        return jdbc.queryForList("SELECT reference, entreprise_id AS \"entrepriseId\", fournisseur, montant, devise, statut, "
            + "created_at AS \"creeLe\", confirme_le AS \"confirmeLe\" FROM transactions_paiement ORDER BY id DESC LIMIT 200");
    }

    /** Paiement non disponible : HTTP 503. */
    public static class PaiementIndisponibleException extends RuntimeException {
        public PaiementIndisponibleException() {
            super("Paiement désactivé : aucun fournisseur, compte marchand ni contrat configuré.");
        }
    }
}
