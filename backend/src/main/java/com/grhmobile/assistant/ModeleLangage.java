package com.grhmobile.assistant;

import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;

/** Fournisseur d'IA conversationnelle, interchangeable (voir ClaudeModeleLangage). */
public interface ModeleLangage {

    /** Un appel d'outil effectué pendant la réponse, avec son résultat (données vérifiables). */
    record AppelOutil(String outil, Map<String, Object> parametres, Map<String, Object> resultat) {}

    record Resultat(String reponse, List<AppelOutil> appels, boolean refus) {}

    /**
     * @param outils    seuls outils que l'utilisateur a le droit d'utiliser
     * @param executeur exécution côté serveur (droits revérifiés à chaque appel)
     */
    Resultat repondre(String question, List<AssistantTools.Definition> outils,
                      BiFunction<String, Map<String, Object>, Map<String, Object>> executeur);
}
