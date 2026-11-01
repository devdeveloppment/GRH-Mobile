package com.grhmobile.service;

import com.grhmobile.audit.Auditable;
import com.grhmobile.security.AccessControlService;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.enums.Role;
import java.util.stream.Collectors;
import java.util.Set;
import java.util.LinkedHashSet;
import java.time.OffsetDateTime;
import java.time.LocalDate;
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
    private final AccessControlService acl;
    private final EmployeRepository employeRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final CalendrierService calendrierService;

    public CongeService(
        CongeRepository congeRepository,
        EmployeeService employeeService,
        AuthenticatedUserService authenticatedUserService,
        NotificationService notificationService,
        AccessControlService acl,
        EmployeRepository employeRepository,
        UtilisateurRepository utilisateurRepository,
        CalendrierService calendrierService
    ) {
        this.calendrierService = calendrierService;
        this.acl = acl;
        this.employeRepository = employeRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.congeRepository = congeRepository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
        this.notificationService = notificationService;
    }

    /**
     * RH et direction voient toutes les demandes ; un manager ne voit que celles de son équipe.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> listAll(String statut) {
        StatutConge filtre = parseStatut(statut);
        List<Conge> source = congeRepository.findAllByOrderByDateDebutDesc();
        if (acl.isManager()) {
            Employe me = acl.currentEmploye()
                .orElseThrow(() -> new ResourceNotFoundException("Employé associé introuvable."));
            Set<Long> team = employeRepository.findTeam(me.getId()).stream()
                .map(Employe::getId)
                .collect(Collectors.toSet());
            source = source.stream().filter(c -> team.contains(c.getEmploye().getId())).toList();
        }
        List<CongeResponse> items = source.stream()
            .filter(c -> filtre == null || c.getStatut() == filtre)
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
        TypeConge type = parseTypeConge(request.typeConge());
        if (request.dateFin().isBefore(request.dateDebut())) {
            throw new BusinessException("La date de fin doit être postérieure ou égale à la date de début.");
        }
        if (request.dateDebut().isBefore(LocalDate.now())) {
            throw new BusinessException("La date de début ne peut pas être dans le passé.");
        }
        // Décompte selon le paramètre CONGES_MODE_DECOMPTE (calendaires, ouvrables ou ouvrés, hors fériés).
        long numberOfDays = calendrierService.compterJoursConge(request.dateDebut(), request.dateFin());
        if (numberOfDays <= 0) {
            throw new BusinessException("La période choisie ne contient aucun jour décompté (week-end ou jours fériés).");
        }
        if (!congeRepository.findOverlapping(employe.getId(), request.dateDebut(), request.dateFin(),
                List.of(StatutConge.EN_ATTENTE, StatutConge.APPROUVE)).isEmpty()) {
            throw new BusinessException("Une demande de congé existe déjà sur cette période.");
        }
        if (type != TypeConge.SANS_SOLDE) {
            // Les demandes en attente réservent une partie du solde
            long reserved = congeRepository.findByEmployeIdOrderByDateDebutDesc(employe.getId()).stream()
                .filter(c -> c.getStatut() == StatutConge.EN_ATTENTE && c.getTypeConge() != TypeConge.SANS_SOLDE)
                .mapToLong(c -> c.getNombreJours() != null ? c.getNombreJours() : 0)
                .sum();
            BigDecimal available = employe.getSoldeConge().subtract(BigDecimal.valueOf(reserved));
            if (available.compareTo(BigDecimal.valueOf(numberOfDays)) < 0) {
                throw new BusinessException("Le solde de congé est insuffisant (disponible : "
                    + available.max(BigDecimal.ZERO).stripTrailingZeros().toPlainString()
                    + " jour(s), demandes en attente incluses).");
            }
        }

        Conge conge = new Conge();
        conge.setEmploye(employe);
        conge.setTypeConge(type);
        conge.setDateDebut(request.dateDebut());
        conge.setDateFin(request.dateFin());
        conge.setNombreJours((int) numberOfDays);
        conge.setMotif(request.motif());
        congeRepository.save(conge);
        notifyValidators(conge);

        return CongeResponse.fromEntity(conge);
    }

    @Auditable(action = "APPROVE_CONGE", entite = "Conge")
    @Transactional
    public void approve(Long id) {
        Conge conge = findById(id);
        if (conge.getStatut() != StatutConge.EN_ATTENTE) {
            throw new BusinessException("Cette demande a déjà été traitée.");
        }
        conge.setStatut(StatutConge.APPROUVE);
        conge.setApprobateur(authenticatedUserService.currentUser());
        conge.setDateApprobation(OffsetDateTime.now());
        if (conge.getTypeConge() != TypeConge.SANS_SOLDE) {
            BigDecimal newBalance = conge.getEmploye().getSoldeConge().subtract(BigDecimal.valueOf(conge.getNombreJours()));
            conge.getEmploye().setSoldeConge(newBalance.max(BigDecimal.ZERO));
        }
        congeRepository.save(conge);
        notifyEmployee(conge, "Congé approuvé",
            "Votre demande de congé du " + conge.getDateDebut() + " au " + conge.getDateFin() + " a été approuvée.",
            "CONGE", "/rh/conges");
    }

    @Auditable(action = "REJECT_CONGE", entite = "Conge")
    @Transactional
    public void reject(Long id, CongeDecisionRequest request) {
        Conge conge = findById(id);
        if (conge.getStatut() != StatutConge.EN_ATTENTE) {
            throw new BusinessException("Cette demande a déjà été traitée.");
        }
        conge.setStatut(StatutConge.REFUSE);
        conge.setApprobateur(authenticatedUserService.currentUser());
        conge.setDateApprobation(OffsetDateTime.now());
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

    /** Prévient le manager de l'employé et les RH qu'une demande attend une décision. */
    private void notifyValidators(Conge conge) {
        Employe employe = conge.getEmploye();
        String nom = employe.getPrenom() + " " + employe.getNom();
        String message = nom + " demande un congé du " + conge.getDateDebut() + " au " + conge.getDateFin()
            + " (" + conge.getNombreJours() + " jour(s)).";
        Set<Long> destinataires = new LinkedHashSet<>();
        if (employe.getManager() != null && employe.getManager().getUtilisateur() != null) {
            destinataires.add(employe.getManager().getUtilisateur().getId());
        }
        utilisateurRepository.findByRoleInAndActifTrue(List.of(Role.HR_ADMIN, Role.RH_MANAGER))
            .forEach(u -> destinataires.add(u.getId()));
        if (employe.getUtilisateur() != null) {
            destinataires.remove(employe.getUtilisateur().getId());
        }
        destinataires.forEach(id -> notificationService.create(id, "Nouvelle demande de congé", message, "CONGE", "/rh/conges"));
    }

    private StatutConge parseStatut(String statut) {
        if (statut == null || statut.isBlank()) {
            return null;
        }
        try {
            return StatutConge.valueOf(statut.trim().toUpperCase());
        } catch (IllegalArgumentException exception) {
            throw new BusinessException("Statut de congé inconnu : " + statut);
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
        try {
            return TypeConge.valueOf(normalized);
        } catch (IllegalArgumentException exception) {
            throw new BusinessException("Type de congé inconnu : " + input
                + ". Types acceptés : Annuel, Maladie, Maternité, Sans solde.");
        }
    }
}
