package com.grhmobile.controller;

import java.util.List;
import java.util.Map;

import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.dto.employee.CompetenceDto;
import com.grhmobile.dto.employee.DocumentDto;
import com.grhmobile.dto.employee.EmployeeRequest;
import com.grhmobile.dto.employee.EmployeeResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Evaluation;
import com.grhmobile.entity.Objectif;
import com.grhmobile.repository.CompetenceRepository;
import com.grhmobile.repository.DocumentRepository;
import com.grhmobile.repository.EvaluationRepository;
import com.grhmobile.repository.ObjectifRepository;
import com.grhmobile.security.AuthenticatedUserService;
import com.grhmobile.service.CongeService;
import com.grhmobile.service.EmployeeService;
import com.grhmobile.service.PaieService;
import com.grhmobile.service.PresenceService;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
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
    private final ObjectifRepository objectifRepository;
    private final EvaluationRepository evaluationRepository;
    private final AuthenticatedUserService authenticatedUserService;

    public EmployeeController(
        EmployeeService employeeService,
        PresenceService presenceService,
        CongeService congeService,
        PaieService paieService,
        DocumentRepository documentRepository,
        CompetenceRepository competenceRepository,
        ObjectifRepository objectifRepository,
        EvaluationRepository evaluationRepository,
        AuthenticatedUserService authenticatedUserService
    ) {
        this.employeeService = employeeService;
        this.presenceService = presenceService;
        this.congeService = congeService;
        this.paieService = paieService;
        this.documentRepository = documentRepository;
        this.competenceRepository = competenceRepository;
        this.objectifRepository = objectifRepository;
        this.evaluationRepository = evaluationRepository;
        this.authenticatedUserService = authenticatedUserService;
    }

    @GetMapping("/me")
    public EmployeeResponse me() {
        Long userId = authenticatedUserService.currentUser().getId();
        return employeeService.getByUserId(userId);
    }

    /** Annuaire interne : coordonnées professionnelles des employés actifs, sans donnée sensible. */
    @GetMapping("/annuaire")
    public Map<String, Object> annuaire() {
        return Map.of("items", employeeService.annuaire());
    }

    @GetMapping("/my-team")
    @PreAuthorize("hasAnyRole('MANAGER','RH_MANAGER')")
    public Map<String, Object> myTeam() {
        return Map.of("items", employeeService.listMyTeam());
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('RH_MANAGER','PAYROLL_OFFICER','DIRECTION','MANAGER','RECRUITER','TRAINER')")
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
    @PreAuthorize("@acl.canViewEmployee(#matricule)")
    public EmployeeResponse get(@PathVariable String matricule) {
        return employeeService.getByMatricule(matricule);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("@acl.can('MANAGE_EMPLOYEES')")
    public EmployeeResponse create(@Valid @RequestBody EmployeeRequest request) {
        return employeeService.create(request);
    }

    @PutMapping("/{matricule}")
    @PreAuthorize("@acl.can('MANAGE_EMPLOYEES')")
    public EmployeeResponse update(@PathVariable String matricule, @Valid @RequestBody EmployeeRequest request) {
        return employeeService.update(matricule, request);
    }

    @DeleteMapping("/{matricule}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("@acl.can('MANAGE_EMPLOYEES')")
    public void archive(@PathVariable String matricule) {
        employeeService.archive(matricule);
    }

    @GetMapping("/{matricule}/presences")
    @PreAuthorize("@acl.canViewEmployee(#matricule)")
    public Map<String, Object> presences(@PathVariable String matricule) {
        return Map.of("items", presenceService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/conges")
    @PreAuthorize("@acl.canViewEmployee(#matricule)")
    public Map<String, Object> conges(@PathVariable String matricule) {
        return Map.of("items", congeService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/paie")
    @PreAuthorize("@acl.canViewPayroll(#matricule)")
    public Map<String, Object> paie(@PathVariable String matricule) {
        return Map.of("items", paieService.listByMatricule(matricule));
    }

    @GetMapping("/{matricule}/documents")
    @PreAuthorize("@acl.canViewEmployee(#matricule)")
    public Map<String, Object> documents(@PathVariable String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return Map.of("items", documentRepository.findByEmployeIdOrderByCreatedAtDesc(employe.getId())
                .stream().map(DocumentDto::fromEntity).toList());
    }

    @GetMapping("/{matricule}/competences")
    @PreAuthorize("@acl.canViewEmployee(#matricule)")
    public Map<String, Object> competences(@PathVariable String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return Map.of("items", competenceRepository.findByEmployeIdOrderByNiveauDesc(employe.getId())
                .stream().map(CompetenceDto::fromEntity).toList());
    }

    @GetMapping("/me/documents")
    public Map<String, Object> myDocuments() {
        Long userId = authenticatedUserService.currentUser().getId();
        Employe employe = employeeService.findByUserId(userId);
        return Map.of("items", documentRepository.findByEmployeIdOrderByCreatedAtDesc(employe.getId())
                .stream().map(DocumentDto::fromEntity).toList());
    }

    @GetMapping("/me/objectifs")
    public Map<String, Object> myObjectifs() {
        Long userId = authenticatedUserService.currentUser().getId();
        Employe employe = employeeService.findByUserId(userId);
        List<Map<String, Object>> items = objectifRepository.findByEmployeIdOrderByCreatedAtDesc(employe.getId())
                .stream()
                .map(o -> {
                    Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("id", o.getId());
                    m.put("titre", o.getTitre());
                    m.put("description", o.getDescription());
                    m.put("statut", o.getStatut());
                    m.put("dateEcheance", o.getDateEcheance() != null ? o.getDateEcheance().toString() : null);
                    return m;
                })
                .toList();
        return Map.of("items", items);
    }

    @GetMapping("/me/evaluations")
    @Transactional(readOnly = true)
    public Map<String, Object> myEvaluations() {
        Long userId = authenticatedUserService.currentUser().getId();
        Employe employe = employeeService.findByUserId(userId);
        List<Map<String, Object>> items = evaluationRepository.findByEmployeIdOrderByPeriodeDesc(employe.getId())
                .stream()
                .map(e -> {
                    Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("id", e.getId());
                    m.put("periode", e.getPeriode());
                    m.put("note", e.getNote());
                    m.put("commentaire", e.getCommentaire());
                    m.put("evaluateur", e.getEvaluateur() != null
                            ? e.getEvaluateur().getPrenom() + " " + e.getEvaluateur().getNom() : null);
                    return m;
                })
                .toList();
        return Map.of("items", items);
    }
}
