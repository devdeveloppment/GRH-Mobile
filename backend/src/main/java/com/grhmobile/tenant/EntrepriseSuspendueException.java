package com.grhmobile.tenant;

/** L'entreprise de l'utilisateur est suspendue : aucun accès à ses données. */
public class EntrepriseSuspendueException extends RuntimeException {
    public EntrepriseSuspendueException() {
        super("L'accès de votre entreprise est suspendu. Contactez l'éditeur de la plateforme.");
    }
}
