package com.grhmobile.integrations.sms;

/**
 * Fournisseur d'envoi de SMS (ou de messages WhatsApp). Implémentation interchangeable :
 * aucun fournisseur n'est choisi ni configuré. Sans configuration, {@link SmsDesactive} est utilisé.
 */
public interface FournisseurSms {

    String nom();

    /** Envoie un message. Ne doit renvoyer ENVOYE que si le fournisseur a accepté le message. */
    ResultatSms envoyer(String numeroE164, String message);

    enum Statut { ENVOYE, NON_ENVOYE, ECHEC }

    record ResultatSms(Statut statut, String referenceFournisseur, String motif) {
        public static ResultatSms nonEnvoye(String motif) {
            return new ResultatSms(Statut.NON_ENVOYE, null, motif);
        }
    }
}
