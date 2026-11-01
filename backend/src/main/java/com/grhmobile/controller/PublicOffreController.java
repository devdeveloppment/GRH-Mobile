package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.recrutement.OffreResponse;
import com.grhmobile.service.RecrutementService;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Accès public (sans authentification) aux offres publiées, pour la page de candidature.
 */
@RestController
@RequestMapping("/api/public/offres")
public class PublicOffreController {

    private final RecrutementService recrutementService;

    public PublicOffreController(RecrutementService recrutementService) {
        this.recrutementService = recrutementService;
    }

    @GetMapping
    public Map<String, Object> list() {
        return recrutementService.listOffres("PUBLIEE");
    }

    @GetMapping("/{id}")
    public OffreResponse get(@PathVariable Long id) {
        return recrutementService.getOffrePubliee(id);
    }
}
