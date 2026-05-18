package com.grhmobile.service;

import com.grhmobile.dto.evaluation.EvaluationRequest;
import com.grhmobile.dto.evaluation.EvaluationResponse;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Evaluation;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EvaluationRepository;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class EvaluationService {

    private final EvaluationRepository evaluationRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authService;
    private final NotificationService notificationService;

    public EvaluationService(EvaluationRepository evaluationRepository,
                              EmployeeService employeeService,
                              AuthenticatedUserService authService,
                              NotificationService notificationService) {
        this.evaluationRepository = evaluationRepository;
        this.employeeService = employeeService;
        this.authService = authService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listAll() {
        List<EvaluationResponse> items = evaluationRepository.findAllByOrderByCreatedAtDesc()
            .stream()
            .map(EvaluationResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listByMatricule(String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        List<EvaluationResponse> items = evaluationRepository
            .findByEmployeIdOrderByPeriodeDesc(employe.getId())
            .stream()
            .map(EvaluationResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listMine() {
        var user = authService.currentUser();
        Employe employe = employeeService.findByUserId(user.getId());
        List<EvaluationResponse> items = evaluationRepository
            .findByEmployeIdOrderByPeriodeDesc(employe.getId())
            .stream()
            .map(EvaluationResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional
    public EvaluationResponse create(EvaluationRequest request) {
        Employe employe = employeeService.findById(request.employeId());

        Evaluation eval = new Evaluation();
        eval.setEmploye(employe);
        eval.setEvaluateur(authService.currentUser());
        applyRequest(eval, request);
        evaluationRepository.save(eval);

        return EvaluationResponse.fromEntity(eval);
    }

    @Transactional
    public EvaluationResponse valider(Long id) {
        Evaluation eval = findById(id);
        if ("VALIDEE".equals(eval.getStatut())) {
            throw new BusinessException("Cette évaluation est déjà validée.");
        }
        eval.setStatut("VALIDEE");
        evaluationRepository.save(eval);

        // Notifier l'employé
        var utilisateur = eval.getEmploye().getUtilisateur();
        if (utilisateur != null) {
            notificationService.create(
                utilisateur.getId(),
                "Évaluation validée",
                "Votre évaluation de la période " + eval.getPeriode() + " a été validée.",
                "EVALUATION",
                "/employee/home"
            );
        }

        return EvaluationResponse.fromEntity(eval);
    }

    @Transactional
    public EvaluationResponse soumettre(Long id) {
        Evaluation eval = findById(id);
        if (!"BROUILLON".equals(eval.getStatut())) {
            throw new BusinessException("Seul un brouillon peut être soumis.");
        }
        eval.setStatut("SOUMISE");
        return EvaluationResponse.fromEntity(evaluationRepository.save(eval));
    }

    private void applyRequest(Evaluation eval, EvaluationRequest request) {
        eval.setPeriode(request.periode().trim());
        eval.setNote(request.note());
        eval.setCommentaire(request.commentaire());
        eval.setType(request.type() != null ? request.type().toUpperCase() : "ANNUELLE");
        eval.setNoteCompetences(request.noteCompetences());
        eval.setNoteObjectifs(request.noteObjectifs());
        eval.setNoteComportement(request.noteComportement());
    }

    private Evaluation findById(Long id) {
        return evaluationRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Évaluation introuvable."));
    }
}
