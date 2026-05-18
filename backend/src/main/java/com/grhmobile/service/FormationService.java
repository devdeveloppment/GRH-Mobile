package com.grhmobile.service;

import com.grhmobile.dto.formation.FormationRequest;
import com.grhmobile.dto.formation.FormationResponse;
import com.grhmobile.entity.Formation;
import com.grhmobile.entity.ParticipationFormation;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.FormationRepository;
import com.grhmobile.repository.ParticipationFormationRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class FormationService {

    private final FormationRepository formationRepository;
    private final ParticipationFormationRepository participationRepository;
    private final EmployeeService employeeService;
    private final NotificationService notificationService;

    public FormationService(FormationRepository formationRepository,
                            ParticipationFormationRepository participationRepository,
                            EmployeeService employeeService,
                            NotificationService notificationService) {
        this.formationRepository = formationRepository;
        this.participationRepository = participationRepository;
        this.employeeService = employeeService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listAll(String statut) {
        List<FormationResponse> items = (statut != null && !statut.isBlank()
            ? formationRepository.findByStatutOrderByDateDebutDesc(statut.toUpperCase())
            : formationRepository.findAllByOrderByDateDebutDesc())
            .stream()
            .map(FormationResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional
    public FormationResponse create(FormationRequest request) {
        Formation formation = new Formation();
        applyRequest(formation, request);
        return FormationResponse.fromEntity(formationRepository.save(formation));
    }

    @Transactional
    public FormationResponse update(Long id, FormationRequest request) {
        Formation formation = findById(id);
        applyRequest(formation, request);
        return FormationResponse.fromEntity(formationRepository.save(formation));
    }

    @Transactional
    public void inscrire(Long formationId, String matricule) {
        Formation formation = findById(formationId);
        var employe = employeeService.findByMatricule(matricule);

        if (participationRepository.existsByFormationIdAndEmployeId(formationId, employe.getId())) {
            throw new BusinessException("Cet employé est déjà inscrit à cette formation.");
        }

        ParticipationFormation participation = new ParticipationFormation();
        participation.setFormation(formation);
        participation.setEmploye(employe);
        participationRepository.save(participation);

        if (employe.getUtilisateur() != null) {
            notificationService.create(
                employe.getUtilisateur().getId(),
                "Inscription formation",
                "Vous avez été inscrit à la formation : " + formation.getTitre(),
                "FORMATION",
                "/employee/home"
            );
        }
    }

    @Transactional
    public void updateParticipation(Long formationId, String matricule, String statut, Integer note) {
        var employe = employeeService.findByMatricule(matricule);
        ParticipationFormation p = participationRepository
            .findByFormationIdAndEmployeId(formationId, employe.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Participation introuvable."));
        p.setStatut(statut.trim().toUpperCase());
        if (note != null) p.setNote(note);
        participationRepository.save(p);
    }

    private void applyRequest(Formation formation, FormationRequest request) {
        formation.setTitre(request.titre().trim());
        formation.setDescription(request.description());
        formation.setType(request.type() != null ? request.type().toUpperCase() : "INTERNE");
        formation.setFormateur(request.formateur());
        formation.setDureeHeures(request.dureeHeures());
        formation.setDateDebut(request.dateDebut());
        formation.setDateFin(request.dateFin());
        formation.setBudget(request.budget());
    }

    public Formation findById(Long id) {
        return formationRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Formation introuvable."));
    }
}
