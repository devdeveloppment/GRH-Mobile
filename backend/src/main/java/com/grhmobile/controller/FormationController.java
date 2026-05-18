package com.grhmobile.controller;

import com.grhmobile.dto.formation.FormationRequest;
import com.grhmobile.dto.formation.FormationResponse;
import com.grhmobile.service.FormationService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/formations")
public class FormationController {

    private final FormationService formationService;

    public FormationController(FormationService formationService) {
        this.formationService = formationService;
    }

    @GetMapping
    public Map<String, Object> list(@RequestParam(required = false) String statut) {
        return formationService.listAll(statut);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','TRAINER')")
    public FormationResponse create(@Valid @RequestBody FormationRequest request) {
        return formationService.create(request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','TRAINER')")
    public FormationResponse update(@PathVariable Long id, @Valid @RequestBody FormationRequest request) {
        return formationService.update(id, request);
    }

    @PostMapping("/{id}/inscrire/{matricule}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','TRAINER','MANAGER')")
    public void inscrire(@PathVariable Long id, @PathVariable String matricule) {
        formationService.inscrire(id, matricule);
    }

    @PutMapping("/{id}/participation/{matricule}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','TRAINER')")
    public void updateParticipation(
        @PathVariable Long id,
        @PathVariable String matricule,
        @RequestParam String statut,
        @RequestParam(required = false) Integer note
    ) {
        formationService.updateParticipation(id, matricule, statut, note);
    }
}
