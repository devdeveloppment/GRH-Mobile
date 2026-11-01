package com.grhmobile.controller;

import java.util.List;
import java.util.Map;

import com.grhmobile.service.EntrepriseService;

import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Administration de la plateforme SaaS (entreprises clientes). Réservé au rôle SUPER_ADMIN.
 * Aucune donnée RH d'une entreprise n'est exposée ici.
 */
@RestController
@RequestMapping("/api/plateforme/entreprises")
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class PlateformeController {

    private final EntrepriseService service;

    public PlateformeController(EntrepriseService service) {
        this.service = service;
    }

    @GetMapping
    public Map<String, Object> lister() {
        List<Map<String, Object>> items = service.lister();
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> creer(@RequestBody Map<String, String> body) {
        return service.creer(body.get("nom"), body.get("slug"), body.get("offre"), body.get("adminEmail"),
            body.get("adminPrenom"), body.get("adminNom"), null);
    }

    @PutMapping("/{id}/statut")
    public Map<String, Object> statut(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return service.changerStatut(id, body.get("statut"));
    }

    @PutMapping("/{id}/offre")
    public Map<String, Object> offre(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return service.changerOffre(id, body.get("offre"));
    }
}
