package com.grhmobile.audit;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marque une méthode de service pour qu'elle soit tracée automatiquement dans audit_logs.
 * action  : code de l'action ex: CREATE_EMPLOYEE
 * entite  : nom de la table/entité ex: Employe
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Auditable {
    String action();
    String entite();
}
