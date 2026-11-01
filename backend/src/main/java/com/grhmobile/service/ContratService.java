package com.grhmobile.service;

import com.grhmobile.exception.BusinessException;
import com.grhmobile.enums.TypeContrat;
import com.grhmobile.audit.Auditable;
import com.grhmobile.dto.contrat.ContratRequest;
import com.grhmobile.dto.contrat.ContratResponse;
import com.grhmobile.entity.Contrat;
import com.grhmobile.entity.Employe;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.ContratRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
public class ContratService {

    private final ContratRepository contratRepository;
    private final EmployeeService employeeService;
    private final PosteService posteService;
    private final DepartementService departementService;
    private final NotificationService notificationService;

    public ContratService(ContratRepository contratRepository,
                          EmployeeService employeeService,
                          PosteService posteService,
                          DepartementService departementService,
                          NotificationService notificationService) {
        this.contratRepository = contratRepository;
        this.employeeService = employeeService;
        this.posteService = posteService;
        this.departementService = departementService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<ContratResponse> listByMatricule(String matricule) {
        Employe employe = employeeService.findByMatricule(matricule);
        return contratRepository.findByEmployeIdOrderByDateDebutDesc(employe.getId())
            .stream()
            .map(ContratResponse::fromEntity)
            .toList();
    }

    @Transactional(readOnly = true)
    public Map<String, Object> contratsExpirantBientot(int jours) {
        LocalDate today = LocalDate.now();
        LocalDate limite = today.plusDays(jours);
        List<ContratResponse> items = contratRepository.findExpiringBefore(today, limite)
            .stream()
            .map(ContratResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Auditable(action = "CREATE_CONTRAT", entite = "Contrat")
    @Transactional
    public ContratResponse create(String matricule, ContratRequest request) {
        Employe employe = employeeService.findByMatricule(matricule);
        String type = request.typeContrat() == null ? "" : request.typeContrat().trim().toUpperCase();
        TypeContrat typeContrat;
        try {
            typeContrat = TypeContrat.valueOf(type);
        } catch (IllegalArgumentException exception) {
            throw new BusinessException("Type de contrat inconnu : " + request.typeContrat() + " (CDI, CDD ou STAGE).");
        }
        if (request.dateFin() != null && request.dateFin().isBefore(request.dateDebut())) {
            throw new BusinessException("La date de fin doit être postérieure à la date de début.");
        }
        if (typeContrat != TypeContrat.CDI && request.dateFin() == null) {
            throw new BusinessException("Une date de fin est obligatoire pour un contrat " + type + ".");
        }
        if (request.salaireBrut().signum() < 0) {
            throw new BusinessException("Le salaire ne peut pas être négatif.");
        }

        // Le nouveau contrat remplace le contrat actif précédent
        contratRepository.findByEmployeIdOrderByDateDebutDesc(employe.getId()).stream()
            .filter(c -> "ACTIF".equals(c.getStatut()))
            .forEach(c -> {
                c.setStatut("TERMINE");
                contratRepository.save(c);
            });

        Contrat contrat = new Contrat();
        contrat.setEmploye(employe);
        applyRequest(contrat, request);
        contrat.setStatut("ACTIF");
        contratRepository.save(contrat);

        // La fiche employé reflète le contrat en vigueur
        employe.setTypeContrat(typeContrat);
        employe.setSalaireBrutBase(request.salaireBrut());
        employe.setDateFinContrat(request.dateFin());
        if (contrat.getPoste() != null) {
            employe.setPosteRef(contrat.getPoste());
            employe.setPoste(contrat.getPoste().getIntitule());
        }
        if (contrat.getDepartement() != null) {
            employe.setDepartement(contrat.getDepartement());
        }

        // Notifier l'employé
        if (employe.getUtilisateur() != null) {
            notificationService.create(
                employe.getUtilisateur().getId(),
                "Nouveau contrat",
                "Un nouveau contrat " + request.typeContrat() + " a été créé pour vous.",
                "CONTRAT",
                "/employee/home"
            );
        }

        return ContratResponse.fromEntity(contrat);
    }

    @Auditable(action = "UPDATE_CONTRAT_STATUT", entite = "Contrat")
    @Transactional
    public ContratResponse updateStatut(Long id, String statut) {
        Contrat contrat = findById(id);
        String nouveau = statut == null ? "" : statut.trim().toUpperCase();
        if (!java.util.List.of("ACTIF", "SUSPENDU", "TERMINE", "RESILIE").contains(nouveau)) {
            throw new BusinessException("Statut de contrat inconnu : " + statut + " (ACTIF, SUSPENDU, TERMINE, RESILIE).");
        }
        contrat.setStatut(nouveau);
        return ContratResponse.fromEntity(contratRepository.save(contrat));
    }

    private void applyRequest(Contrat contrat, ContratRequest request) {
        contrat.setTypeContrat(request.typeContrat().trim().toUpperCase());
        contrat.setDateDebut(request.dateDebut());
        contrat.setDateFin(request.dateFin());
        contrat.setSalaireBrut(request.salaireBrut());
        contrat.setDocumentUrl(request.documentUrl());

        Long posteId = request.posteId();
        contrat.setPoste(posteId != null ? posteService.findById(posteId) : null);

        Long deptId = request.departementId();
        contrat.setDepartement(deptId != null ? departementService.findById(deptId) : null);
    }

    private Contrat findById(Long id) {
        return contratRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Contrat introuvable."));
    }
}
