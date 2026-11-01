package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.conge.CongeDecisionRequest;
import com.grhmobile.dto.conge.CongeRequest;
import com.grhmobile.dto.conge.CongeResponse;
import com.grhmobile.service.CongeService;

import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/conges")
public class CongeController {

    private final CongeService congeService;

    public CongeController(CongeService congeService) {
        this.congeService = congeService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('RH_MANAGER','MANAGER','DIRECTION')")
    public Map<String, Object> list(@RequestParam(required = false) String statut) {
        return congeService.listAll(statut);
    }

    @GetMapping("/me")
    public Map<String, Object> listMine() {
        return congeService.listMine();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CongeResponse create(@Valid @RequestBody CongeRequest request) {
        return congeService.submit(request);
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("@acl.canDecideConge(#id)")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void approve(@PathVariable Long id) {
        congeService.approve(id);
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("@acl.canDecideConge(#id)")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(@PathVariable Long id, @RequestBody(required = false) CongeDecisionRequest request) {
        congeService.reject(id, request != null ? request : new CongeDecisionRequest(null));
    }
}
