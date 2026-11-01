package com.grhmobile.controller;

import com.grhmobile.dto.contrat.ContratRequest;
import com.grhmobile.dto.contrat.ContratResponse;
import com.grhmobile.service.ContratService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ContratController {

    private final ContratService contratService;

    public ContratController(ContratService contratService) {
        this.contratService = contratService;
    }

    @GetMapping("/employees/{matricule}/contrats")
    @PreAuthorize("@acl.canViewPayroll(#matricule)")
    public Map<String, Object> listByEmploye(@PathVariable String matricule) {
        List<ContratResponse> items = contratService.listByMatricule(matricule);
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping("/employees/{matricule}/contrats")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public ContratResponse create(@PathVariable String matricule,
                                   @Valid @RequestBody ContratRequest request) {
        return contratService.create(matricule, request);
    }

    @PutMapping("/contrats/{id}/statut")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public ContratResponse updateStatut(@PathVariable Long id,
                                        @RequestParam String statut) {
        return contratService.updateStatut(id, statut);
    }

    @GetMapping("/contrats/expirant")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','PAYROLL_OFFICER')")
    public Map<String, Object> expirantBientot(@RequestParam(defaultValue = "30") int jours) {
        return contratService.contratsExpirantBientot(jours);
    }
}
