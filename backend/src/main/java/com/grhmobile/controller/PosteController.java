package com.grhmobile.controller;

import com.grhmobile.dto.poste.PosteRequest;
import com.grhmobile.dto.poste.PosteResponse;
import com.grhmobile.service.PosteService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/postes")
public class PosteController {

    private final PosteService posteService;

    public PosteController(PosteService posteService) {
        this.posteService = posteService;
    }

    @GetMapping
    public Map<String, Object> list(@RequestParam(required = false) Long departementId) {
        List<PosteResponse> items = departementId != null
            ? posteService.listByDepartement(departementId)
            : posteService.listAll();
        return Map.of("items", items, "total", items.size());
    }

    @GetMapping("/{id}")
    public PosteResponse getById(@PathVariable Long id) {
        return posteService.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public PosteResponse create(@Valid @RequestBody PosteRequest request) {
        return posteService.create(request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER')")
    public PosteResponse update(@PathVariable Long id, @Valid @RequestBody PosteRequest request) {
        return posteService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN')")
    public void desactiver(@PathVariable Long id) {
        posteService.desactiver(id);
    }
}
