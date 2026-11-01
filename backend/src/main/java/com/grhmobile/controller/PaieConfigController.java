package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.service.PaieConfigService;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/** Configuration du moteur de paie : rubriques, paramètres datés, lignes de bulletin. */
@RestController
@RequestMapping("/api/paie")
@PreAuthorize("@acl.can('MANAGE_PAIE')")
public class PaieConfigController {

    private final PaieConfigService service;

    public PaieConfigController(PaieConfigService service) {
        this.service = service;
    }

    @GetMapping("/rubriques")
    public Map<String, Object> rubriques() {
        return service.listRubriques();
    }

    @PostMapping("/rubriques")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> createRubrique(@RequestBody Map<String, Object> body) {
        return service.saveRubrique(null, body);
    }

    @PutMapping("/rubriques/{id}")
    public Map<String, Object> updateRubrique(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        return service.saveRubrique(id, body);
    }

    @GetMapping("/parametres")
    public Map<String, Object> parametres() {
        return service.listParametres();
    }

    @PostMapping("/parametres")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> createParametre(@RequestBody Map<String, Object> body) {
        return service.createParametre(body);
    }

    /** Soumet un paramètre à validation (BROUILLON -> SOUMIS). */
    @PutMapping("/parametres/{id}/soumission")
    public Map<String, Object> soumettreParametre(@PathVariable Long id, @RequestBody(required = false) Map<String, Object> body) {
        return service.soumettreParametre(id, body == null ? Map.of() : body);
    }

    /** Enregistre la validation d'un paramètre (source officielle + validateur). */
    @PutMapping("/parametres/{id}/validation")
    public Map<String, Object> validerParametre(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        return service.validerParametre(id, body);
    }

    @GetMapping("/{ficheId}/lignes")
    public Map<String, Object> lignes(@PathVariable Long ficheId) {
        return service.lignes(ficheId);
    }
}
