package com.grhmobile.service;

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

    @Transactional
    public ContratResponse create(String matricule, ContratRequest request) {
        Employe employe = employeeService.findByMatricule(matricule);

        Contrat contrat = new Contrat();
        contrat.setEmploye(employe);
        applyRequest(contrat, request);
        contratRepository.save(contrat);

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

    @Transactional
    public ContratResponse updateStatut(Long id, String statut) {
        Contrat contrat = findById(id);
        contrat.setStatut(statut.trim().toUpperCase());
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
