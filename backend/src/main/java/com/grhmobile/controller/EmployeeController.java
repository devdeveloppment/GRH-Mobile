package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.dto.employee.CompetenceDto;
import com.grhmobile.dto.employee.DocumentDto;
import com.grhmobile.dto.employee.EmployeeRequest;
import com.grhmobile.dto.employee.EmployeeResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.repository.CompetenceRepository;
import com.grhmobile.repository.DocumentRepository;
import com.grhmobile.service.CongeService;
import com.grhmobile.service.EmployeeService;
import com.grhmobile.service.PaieService;
import com.grhmobile.service.PresenceService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;
    private final PresenceService presenceService;
    private final CongeService congeService;
    private final PaieService paieService;
    private final DocumentRepository documentRepository;
    private final CompetenceRepository competenceRepository;

    public EmployeeController(
        EmployeeService employeeService,
        PresenceService presenceService,
        CongeService congeService,
        PaieService paieService,
        DocumentRepository documentRepository,
        CompetenceRepository competenceRepository
    ) {
        this.employeeService = employeeService;
        this.presenceService = presenceService;
        this.congeService = congeService;
        this.paieService = paieService;
        this.documentRepository = documentRepository;
        this.competenceRepository = competenceRepository;
    }

    @GetMapping
    public PagedResponse<EmployeeResponse> list(
        @RequestParam(defaultValue = "1") int page,
        @RequestParam(defaultValue = "20") int limit,
        @RequestParam(required = false) String query,
        @RequestParam(required = false) String statut,
        @RequestParam(required = false) String service
    ) {
        return employeeService.search(query, statut, service, page, limit);
    }

    @GetMapping("/{matricule}")
    public EmployeeResponse get(@PathVariable String matricule) {
        return employeeService.getByMatricule(matricule);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EmployeeResponse create(@Valid @RequestBody EmployeeRequest request) {
        return employeeService.create(request);
    }

    @PutMapping("/{matricule}")
    public EmployeeResponse update(@PathVariable String matricule, @Valid @RequestBody EmployeeRequest request) {
        return employeeService.update(matricule, request);
    }

    @DeleteMapping("/{matricule}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void archive(@PathVariable String matricule) {
        employeeService.archive(matricule);
    }

    @GetMapping("/{matricule}/presences")
    public Map<String, Object> presences(@PathVariable String matricule) {
        return Map.of("items", presenceService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/conges")
    public Map<String, Object> conges(@PathVariable String matricule) {
        return Map.of("items", congeService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/paie")
    public Map<String, Object> paie(@PathVariable String matricule) {
        return Map.of("items", paieService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/documents")
    public Map<String, Object> documents(@PathVariable String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return Map.of("items", documentRepository.findByEmployeIdOrderByCreatedAtDesc(employe.getId())
                .stream().map(DocumentDto::fromEntity).toList());
    }

    @GetMapping("/{matricule}/competences")
    public Map<String, Object> competences(@PathVariable String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return Map.of("items", competenceRepository.findByEmployeIdOrderByNiveauDesc(employe.getId())
                .stream().map(CompetenceDto::fromEntity).toList());
    }
}
