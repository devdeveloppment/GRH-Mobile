package com.grhmobile.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.grhmobile.audit.Auditable;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.TacheIntegration;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.security.AuthenticatedUserService;
import com.grhmobile.repository.TacheIntegrationRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Listes de tâches d'arrivée et de départ. Les modèles sont des listes de travail génériques
 * (organisationnelles), sans portée légale ; chaque tâche reste modifiable.
 */
@Service
public class IntegrationService {

    static final List<String> MODELE_ARRIVEE = List.of(
        "Préparer le poste de travail et le matériel",
        "Créer les accès (messagerie, applications)",
        "Collecter les pièces administratives",
        "Signer le contrat et le remettre à l'employé",
        "Présenter l'équipe et le règlement intérieur",
        "Planifier un point de suivi à la fin de la période d'essai");

    static final List<String> MODELE_DEPART = List.of(
        "Récupérer le matériel attribué",
        "Désactiver les accès",
        "Préparer le solde de tout compte (à valider par la paie)",
        "Remettre les documents de fin de contrat",
        "Organiser l'entretien de départ");

    private final TacheIntegrationRepository repository;
    private final EmployeRepository employeRepository;
    private final AuthenticatedUserService authenticatedUserService;

    public IntegrationService(TacheIntegrationRepository repository, EmployeRepository employeRepository,
                              AuthenticatedUserService authenticatedUserService) {
        this.repository = repository;
        this.employeRepository = employeRepository;
        this.authenticatedUserService = authenticatedUserService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> liste(String matricule) {
        Employe e = employe(matricule);
        List<Map<String, Object>> items = repository.findByEmployeIdOrderByTypeAscOrdreAsc(e.getId()).stream()
            .map(this::toMap).toList();
        long faites = items.stream().filter(m -> Boolean.TRUE.equals(m.get("faite"))).count();
        return Map.of("items", items, "total", items.size(), "faites", faites);
    }

    @Auditable(action = "GENERATE_CHECKLIST", entite = "TacheIntegration")
    @Transactional
    public Map<String, Object> generer(String matricule, String type, LocalDate echeance) {
        if (!"ARRIVEE".equals(type) && !"DEPART".equals(type)) {
            throw new BusinessException("Type attendu : ARRIVEE ou DEPART.");
        }
        Employe e = employe(matricule);
        if (repository.existsByEmployeIdAndType(e.getId(), type)) {
            throw new BusinessException("Une liste " + type + " existe déjà pour cet employé.");
        }
        List<String> modele = "ARRIVEE".equals(type) ? MODELE_ARRIVEE : MODELE_DEPART;
        for (int i = 0; i < modele.size(); i++) {
            TacheIntegration t = new TacheIntegration();
            t.setEmploye(e);
            t.setType(type);
            t.setLibelle(modele.get(i));
            t.setOrdre((i + 1) * 10);
            t.setEcheance(echeance);
            repository.save(t);
        }
        return liste(matricule);
    }

    @Transactional
    public Map<String, Object> ajouter(String matricule, String type, String libelle, LocalDate echeance) {
        if (!"ARRIVEE".equals(type) && !"DEPART".equals(type)) {
            throw new BusinessException("Type attendu : ARRIVEE ou DEPART.");
        }
        if (libelle == null || libelle.isBlank()) {
            throw new BusinessException("Le libellé est obligatoire.");
        }
        Employe e = employe(matricule);
        TacheIntegration t = new TacheIntegration();
        t.setEmploye(e);
        t.setType(type);
        t.setLibelle(libelle.trim());
        t.setOrdre(1000);
        t.setEcheance(echeance);
        repository.save(t);
        return toMap(t);
    }

    @Auditable(action = "UPDATE_CHECKLIST_TASK", entite = "TacheIntegration")
    @Transactional
    public Map<String, Object> marquer(Long id, boolean faite) {
        TacheIntegration t = repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Tâche introuvable."));
        t.setFaite(faite);
        t.setFaitePar(faite ? authenticatedUserService.currentUser() : null);
        t.setFaiteLe(faite ? OffsetDateTime.now() : null);
        repository.save(t);
        return toMap(t);
    }

    private Employe employe(String matricule) {
        return employeRepository.findByMatricule(matricule)
            .orElseThrow(() -> new ResourceNotFoundException("Employé introuvable."));
    }

    private Map<String, Object> toMap(TacheIntegration t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("type", t.getType());
        m.put("libelle", t.getLibelle());
        m.put("echeance", t.getEcheance() != null ? t.getEcheance().toString() : null);
        m.put("faite", t.isFaite());
        m.put("faiteLe", t.getFaiteLe() != null ? t.getFaiteLe().toString() : null);
        return m;
    }
}
