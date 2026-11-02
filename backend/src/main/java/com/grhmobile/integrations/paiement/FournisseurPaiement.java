package com.grhmobile.integrations.paiement;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Fournisseur de paiement mobile money (agrégateur ou opérateur). Implémentation interchangeable ;
 * aucun fournisseur n'est configuré. Le statut final d'une transaction ne provient JAMAIS du client :
 * uniquement d'une notification serveur à serveur dont la signature a été vérifiée, ou d'une
 * interrogation directe du fournisseur.
 */
public interface FournisseurPaiement {

    String nom();

    boolean actif();

    /** Crée la transaction chez le fournisseur ; renvoie sa référence et l'URL ou l'instruction de paiement. */
    Initiation initier(String referenceInterne, BigDecimal montant, String devise, String description);

    /** Vérifie la signature d'une notification (callback) avec le secret du fournisseur. */
    boolean signatureValide(String corpsBrut, Map<String, String> entetes);

    /** Extrait de la notification : référence interne et statut (REUSSI, ECHEC). */
    Notification lireNotification(String corpsBrut);

    record Initiation(String referenceFournisseur, String urlPaiement) {
    }

    record Notification(String referenceInterne, String statut, BigDecimal montant) {
    }
}
