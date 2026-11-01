package com.grhmobile.tenant;

import java.util.function.Supplier;

/**
 * Entreprise courante (tenant) du thread.
 *
 * <ul>
 *   <li>{@code null} : aucune entreprise — fail closed : Hibernate filtre sur une valeur
 *       inexistante et PostgreSQL (RLS) ne renvoie aucune ligne.</li>
 *   <li>{@link #ROOT} : contexte système (connexion, tâches planifiées, plateforme) — aucun
 *       filtre ; réservé au code serveur, jamais dérivé d'une requête utilisateur.</li>
 * </ul>
 */
public final class TenantContext {

    /** Valeur « système » : lecture de toutes les entreprises (aucune écriture possible : FK). */
    public static final long ROOT = -1L;

    /** Valeur utilisée quand aucune entreprise n'est définie : ne correspond à aucune ligne. */
    public static final long AUCUNE = 0L;

    private static final ThreadLocal<Long> CURRENT = new ThreadLocal<>();

    private TenantContext() {
    }

    public static Long get() {
        return CURRENT.get();
    }

    public static void set(Long entrepriseId) {
        CURRENT.set(entrepriseId);
    }

    public static void clear() {
        CURRENT.remove();
    }

    /** Exécute un traitement pour une entreprise donnée, puis restaure le contexte précédent. */
    public static <T> T executer(long entrepriseId, Supplier<T> action) {
        Long previous = CURRENT.get();
        CURRENT.set(entrepriseId);
        try {
            return action.get();
        } finally {
            if (previous == null) {
                CURRENT.remove();
            } else {
                CURRENT.set(previous);
            }
        }
    }

    public static void executer(long entrepriseId, Runnable action) {
        executer(entrepriseId, () -> {
            action.run();
            return null;
        });
    }

    /** Contexte système (sans filtre). À n'utiliser que pour des lectures techniques maîtrisées. */
    public static <T> T systeme(Supplier<T> action) {
        return executer(ROOT, action);
    }
}
