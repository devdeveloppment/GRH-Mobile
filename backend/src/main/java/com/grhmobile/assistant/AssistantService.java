package com.grhmobile.assistant;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeSet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.security.AuthenticatedUserService;
import com.grhmobile.service.AuditLogService;

import org.springframework.stereotype.Service;

/**
 * Orchestration de l'assistant : contrôle d'activation, outils autorisés, journalisation.
 * Lecture seule : aucun outil ne modifie de données.
 */
@Service
public class AssistantService {

    private static final int MAX_QUESTION = 1000;

    private final Optional<ModeleLangage> modele;
    private final AssistantTools tools;
    private final AuditLogService auditLogService;
    private final AuthenticatedUserService authenticatedUserService;
    private final ObjectMapper objectMapper;

    public AssistantService(Optional<ModeleLangage> modele, AssistantTools tools, AuditLogService auditLogService,
                            AuthenticatedUserService authenticatedUserService, ObjectMapper objectMapper) {
        this.modele = modele;
        this.tools = tools;
        this.auditLogService = auditLogService;
        this.authenticatedUserService = authenticatedUserService;
        this.objectMapper = objectMapper;
    }

    public Map<String, Object> statut() {
        return Map.of(
            "actif", modele.isPresent(),
            "outils", tools.autorises().stream().map(d -> Map.of("nom", d.name(), "description", d.description())).toList(),
            "message", modele.isPresent() ? "Assistant disponible."
                : "Assistant non configuré : un administrateur doit fournir une clé de fournisseur d'IA (voir la documentation).");
    }

    /** Exécution directe d'un outil (données vérifiables, sans IA). */
    public Map<String, Object> outil(String nom, Map<String, Object> input) {
        Map<String, Object> resultat = tools.executer(nom, input);
        journaliser("ASSISTANT_OUTIL", Map.of("outil", nom));
        return Map.of("outil", nom, "resultat", resultat, "noms", tools.noms(matricules(resultat)));
    }

    public Map<String, Object> demander(String question) {
        if (question == null || question.isBlank()) {
            throw new BusinessException("La question est vide.");
        }
        if (question.length() > MAX_QUESTION) {
            throw new BusinessException("Question trop longue (" + MAX_QUESTION + " caractères maximum).");
        }
        if (modele.isEmpty()) {
            throw new AssistantIndisponibleException();
        }
        ModeleLangage.Resultat r = modele.get().repondre(question.trim(), tools.autorises(), tools::executer);

        List<String> outils = r.appels().stream().map(ModeleLangage.AppelOutil::outil).toList();
        journaliser("ASSISTANT_QUESTION", Map.of(
            "question", question.length() > 200 ? question.substring(0, 200) + "…" : question,
            "outils", outils, "refus", r.refus()));

        TreeSet<String> matricules = new TreeSet<>();
        r.appels().forEach(a -> matricules.addAll(matricules(a.resultat())));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("reponse", r.reponse());
        out.put("donnees", r.appels());
        out.put("noms", tools.noms(List.copyOf(matricules)));
        out.put("avertissement", "Réponse générée par IA à partir des données ci-jointes : vérifiez avant toute décision.");
        return out;
    }

    private void journaliser(String action, Map<String, Object> detail) {
        try {
            auditLogService.log(authenticatedUserService.currentUser().getId(), action, "Assistant", null, null,
                objectMapper.writeValueAsString(detail), null);
        } catch (Exception ignored) {
            // La journalisation ne doit pas bloquer la réponse.
        }
    }

    /** Matricules présents dans un résultat d'outil (pour la résolution des noms côté serveur). */
    @SuppressWarnings("unchecked")
    static List<String> matricules(Object value) {
        TreeSet<String> out = new TreeSet<>();
        if (value instanceof Map<?, ?> map) {
            map.forEach((k, v) -> {
                if ("matricule".equals(k) && v instanceof String s) out.add(s);
                else if ("matricules".equals(k) && v instanceof List<?> l) l.forEach(x -> out.add(String.valueOf(x)));
                else out.addAll(matricules(v));
            });
        } else if (value instanceof List<?> list) {
            list.forEach(x -> out.addAll(matricules(x)));
        }
        return List.copyOf(out);
    }
}
