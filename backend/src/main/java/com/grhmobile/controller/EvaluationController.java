package com.grhmobile.controller;

import com.grhmobile.dto.evaluation.EvaluationRequest;
import com.grhmobile.dto.evaluation.EvaluationResponse;
import com.grhmobile.service.EvaluationService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/evaluations")
public class EvaluationController {

    private final EvaluationService evaluationService;

    public EvaluationController(EvaluationService evaluationService) {
        this.evaluationService = evaluationService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','MANAGER','DIRECTION')")
    public Map<String, Object> listAll() {
        return evaluationService.listAll();
    }

    @GetMapping("/me")
    public Map<String, Object> listMine() {
        return evaluationService.listMine();
    }

    @GetMapping("/employe/{matricule}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','MANAGER')")
    public Map<String, Object> listByMatricule(@PathVariable String matricule) {
        return evaluationService.listByMatricule(matricule);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','MANAGER')")
    public EvaluationResponse create(@Valid @RequestBody EvaluationRequest request) {
        return evaluationService.create(request);
    }

    @PostMapping("/{id}/soumettre")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','MANAGER')")
    public EvaluationResponse soumettre(@PathVariable Long id) {
        return evaluationService.soumettre(id);
    }

    @PostMapping("/{id}/valider")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public EvaluationResponse valider(@PathVariable Long id) {
        return evaluationService.valider(id);
    }
}
