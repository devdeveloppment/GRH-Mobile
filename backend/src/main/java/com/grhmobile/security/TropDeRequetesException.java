package com.grhmobile.security;

/** Limite de requêtes atteinte : traduite en HTTP 429 avec l'en-tête Retry-After. */
public class TropDeRequetesException extends RuntimeException {

    private final long attenteSecondes;

    public TropDeRequetesException(long attenteSecondes) {
        super("Trop de tentatives. Réessayez dans " + attenteSecondes + " secondes.");
        this.attenteSecondes = attenteSecondes;
    }

    public long getAttenteSecondes() {
        return attenteSecondes;
    }
}
