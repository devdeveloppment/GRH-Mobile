package com.grhmobile.controller;

import java.time.LocalDate;
import java.util.Map;

import com.grhmobile.exception.BusinessException;
import com.grhmobile.service.IntegrationService;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/** Listes de tâches d'arrivée et de départ (gestion du personnel). */
@RestController
@RequestMapping("/api")
@PreAuthorize("@acl.can('MANAGE_EMPLOYEES')")
public class IntegrationController {

    private final IntegrationService service;

    public IntegrationController(IntegrationService service) {
        this.service = service;
    }

    @GetMapping("/employees/{matricule}/integration")
    public Map<String, Object> liste(@PathVariable String matricule) {
        return service.liste(matricule);
    }

    @PostMapping("/employees/{matricule}/integration/{type}")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> generer(@PathVariable String matricule, @PathVariable String type,
                                       @RequestBody(required = false) Map<String, String> body) {
        return service.generer(matricule, type.toUpperCase(), date(body));
    }

    @PostMapping("/employees/{matricule}/integration/{type}/taches")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> ajouter(@PathVariable String matricule, @PathVariable String type,
                                       @RequestBody Map<String, String> body) {
        Map<String, Object> t = service.ajouter(matricule, type.toUpperCase(), body.get("libelle"), date(body));
        if (body.get("responsable") != null) {
            t = service.marquer((Long) t.get("id"), Map.of("responsable", body.get("responsable")));
        }
        return t;
    }

    /** Mise à jour d'une tâche : faite, responsable, échéance, commentaire. */
    @PutMapping("/integration/taches/{id}")
    public Map<String, Object> marquer(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        return service.marquer(id, body);
    }

    /** Vue d'ensemble des arrivées et départs en cours ou clôturés. */
    @org.springframework.web.bind.annotation.GetMapping("/integration/processus")
    public Map<String, Object> processus() {
        return service.processus();
    }

    @PostMapping("/employees/{matricule}/integration/{type}/cloture")
    public Map<String, Object> cloturer(@PathVariable String matricule, @PathVariable String type,
                                        @RequestBody(required = false) Map<String, String> body) {
        return service.cloturer(matricule, type.toUpperCase(), body == null ? null : body.get("commentaire"));
    }

    private static LocalDate date(Map<String, String> body) {
        if (body == null || body.get("echeance") == null || body.get("echeance").isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(body.get("echeance"));
        } catch (Exception e) {
            throw new BusinessException("Échéance invalide (format AAAA-MM-JJ).");
        }
    }
}
