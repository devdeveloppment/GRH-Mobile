package com.grhmobile.service;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

import com.grhmobile.dto.conge.CongeDecisionRequest;
import com.grhmobile.dto.conge.CongeRequest;
import com.grhmobile.dto.conge.CongeResponse;
import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.TypeConge;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CongeService {

    private final CongeRepository congeRepository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;
    private final NotificationService notificationService;

    public CongeService(
        CongeRepository congeRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService,
        NotificationService notificationService
    ) {
        this.congeRepository = congeRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listAll() {
        List<CongeResponse> items = congeRepository.findAll()
            .stream()
            .sorted((left, right) -> right.getDateDebut().compareTo(left.getDateDebut()))
            .map(CongeResponse::fromEntity)
            .toList();
        return Map.of("items", items, "soldeRestant", 0);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listMine() {
        Employe employe = employeeService.findByUserId(authenticatedUserService.currentUser().getId());
        List<CongeResponse> items = congeRepository.findByEmployeIdOrderByDateDebutDesc(employe.getId())
            .stream()
            .map(CongeResponse::fromEntity)
            .toList();
        return Map.of("items", items, "soldeRestant", employe.getSoldeConge());
    }

    @Transactional
    public CongeResponse submit(CongeRequest request) {
        Employe employe = employeeService.findByUserId(authenticatedUserService.currentUser().getId());
        long numberOfDays = ChronoUnit.DAYS.between(request.dateDebut(), request.dateFin()) + 1;
        if (numberOfDays <= 0) {
            throw new BusinessException("La période de congé est invalide.");
        }
        if (employe.getSoldeConge().compareTo(BigDecimal.valueOf(numberOfDays)) < 0
            && !TypeConge.SANS_SOLDE.name().equalsIgnoreCase(request.typeConge())) {
            throw new BusinessException("Le solde de congé est insuffisant.");
        }

        Conge conge = new Conge();
        conge.setEmploye(employe);
        conge.setTypeConge(parseTypeConge(request.typeConge()));
        conge.setDateDebut(request.dateDebut());
        conge.setDateFin(request.dateFin());
        conge.setNombreJours((int) numberOfDays);
        conge.setMotif(request.motif());
        congeRepository.save(conge);

        return CongeResponse.fromEntity(conge);
    }

    @Transactional
    public void approve(Long id) {
        Conge conge = findById(id);
        if (conge.getStatut() != StatutConge.EN_ATTENTE) {
            throw new BusinessException("Cette demande a déjà été traitée.");
        }
        conge.setStatut(StatutConge.APPROUVE);
        if (conge.getTypeConge() != TypeConge.SANS_SOLDE) {
            BigDecimal newBalance = conge.getEmploye().getSoldeConge().subtract(BigDecimal.valueOf(conge.getNombreJours()));
            conge.getEmploye().setSoldeConge(newBalance.max(BigDecimal.ZERO));
        }
        congeRepository.save(conge);
        notifyEmployee(conge, "Congé approuvé",
            "Votre demande de congé du " + conge.getDateDebut() + " au " + conge.getDateFin() + " a été approuvée.",
            "CONGE", "/rh/conges");
    }

    @Transactional
    public void reject(Long id, CongeDecisionRequest request) {
        Conge conge = findById(id);
        if (conge.getStatut() != StatutConge.EN_ATTENTE) {
            throw new BusinessException("Cette demande a déjà été traitée.");
        }
        conge.setStatut(StatutConge.REFUSE);
        conge.setCommentaire(request.commentaire());
        congeRepository.save(conge);
        notifyEmployee(conge, "Congé refusé",
            "Votre demande de congé du " + conge.getDateDebut() + " au " + conge.getDateFin() + " a été refusée.",
            "CONGE", "/rh/conges");
    }

    private void notifyEmployee(Conge conge, String titre, String message, String type, String redirectTo) {
        var utilisateur = conge.getEmploye().getUtilisateur();
        if (utilisateur != null) {
            notificationService.create(utilisateur.getId(), titre, message, type, redirectTo);
        }
    }

    @Transactional(readOnly = true)
    public List<CongeResponse> listByMatricule(String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return congeRepository.findByEmployeIdOrderByDateDebutDesc(employe.getId())
            .stream()
            .map(CongeResponse::fromEntity)
            .toList();
    }

    private Conge findById(Long id) {
        return congeRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Demande de congé introuvable."));
    }

    private TypeConge parseTypeConge(String input) {
        String normalized = Normalizer.normalize(input, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .trim()
            .toUpperCase()
            .replace(' ', '_');
        return TypeConge.valueOf(normalized);
    }
}
