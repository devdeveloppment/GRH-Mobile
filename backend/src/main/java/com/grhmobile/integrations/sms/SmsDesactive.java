package com.grhmobile.integrations.sms;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Fournisseur par défaut : n'envoie rien et le dit (statut NON_ENVOYE). Aucun compte, aucune clé et
 * aucun contrat n'existent à ce jour ; voir docs/INTEGRATIONS_SMS_PAIEMENT.md.
 */
@Component
public class SmsDesactive implements FournisseurSms {

    private static final Logger log = LoggerFactory.getLogger(SmsDesactive.class);

    @Override
    public String nom() {
        return "DESACTIVE";
    }

    @Override
    public ResultatSms envoyer(String numeroE164, String message) {
        log.debug("SMS non envoyé (aucun fournisseur configuré)");
        return ResultatSms.nonEnvoye("Envoi de SMS désactivé : aucun fournisseur configuré.");
    }
}
