package com.grhmobile.controller;

import com.grhmobile.dto.departement.DepartementRequest;
import com.grhmobile.dto.departement.DepartementResponse;
import com.grhmobile.service.DepartementService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/departements")
public class DepartementController {

    private final DepartementService departementService;

    public DepartementController(DepartementService departementService) {
        this.departementService = departementService;
    }

    @GetMapping
    public Map<String, Object> list() {
        List<DepartementResponse> items = departementService.listAll();
        return Map.of("items", items, "total", items.size());
    }

    @GetMapping("/organigramme")
    public Map<String, Object> organigramme() {
        List<DepartementResponse> tree = departementService.organigramme();
        return Map.of("tree", tree);
    }

    @GetMapping("/{id}")
    public DepartementResponse getById(@PathVariable Long id) {
        return departementService.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public DepartementResponse create(@Valid @RequestBody DepartementRequest request) {
        return departementService.create(request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public DepartementResponse update(@PathVariable Long id,
                                      @Valid @RequestBody DepartementRequest request) {
        return departementService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN')")
    public void desactiver(@PathVariable Long id) {
        departementService.desactiver(id);
    }
}
