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
    private com.grhmobile.repository.ClotureIntegrationRepository clotureRepository;

    @org.springframework.beans.factory.annotation.Autowired
    void setClotureRepository(com.grhmobile.repository.ClotureIntegrationRepository clotureRepository) {
        this.clotureRepository = clotureRepository;
    }

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
        Map<String, Object> clotures = new LinkedHashMap<>();
        for (com.grhmobile.entity.ClotureIntegration c : clotureRepository.findByEmployeId(e.getId())) {
            clotures.put(c.getType(), c.getClotureLe().toString());
        }
        return Map.of("items", items, "total", items.size(), "faites", faites, "clotures", clotures,
            "employe", Map.of("matricule", e.getMatricule(), "nom", e.getNom(), "prenom", e.getPrenom()));
    }

    /** Vue d'ensemble : un processus (employé + type) par ligne, avec avancement, retards et clôture. */
    @Transactional(readOnly = true)
    public Map<String, Object> processus() {
        LocalDate aujourdhui = LocalDate.now();
        Map<String, Map<String, Object>> parCle = new LinkedHashMap<>();
        for (TacheIntegration t : repository.toutesAvecEmploye()) {
            Employe e = t.getEmploye();
            Map<String, Object> p = parCle.computeIfAbsent(e.getId() + ":" + t.getType(), k -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("matricule", e.getMatricule());
                m.put("nom", e.getNom());
                m.put("prenom", e.getPrenom());
                m.put("type", t.getType());
                m.put("total", 0);
                m.put("faites", 0);
                m.put("enRetard", 0);
                m.put("prochaineEcheance", null);
                m.put("cloture", clotureRepository.findByEmployeIdAndType(e.getId(), t.getType())
                    .map(c -> c.getClotureLe().toString()).orElse(null));
                return m;
            });
            p.put("total", (int) p.get("total") + 1);
            if (t.isFaite()) {
                p.put("faites", (int) p.get("faites") + 1);
            } else if (t.getEcheance() != null) {
                if (t.getEcheance().isBefore(aujourdhui)) {
                    p.put("enRetard", (int) p.get("enRetard") + 1);
                }
                String prochaine = (String) p.get("prochaineEcheance");
                if (prochaine == null || t.getEcheance().toString().compareTo(prochaine) < 0) {
                    p.put("prochaineEcheance", t.getEcheance().toString());
                }
            }
        }
        List<Map<String, Object>> items = new java.util.ArrayList<>(parCle.values());
        return Map.of("items", items, "total", items.size());
    }

    /** Clôture le processus : toutes les tâches doivent être faites. */
    @Auditable(action = "CLOSE_CHECKLIST", entite = "TacheIntegration")
    @Transactional
    public Map<String, Object> cloturer(String matricule, String type, String commentaire) {
        Employe e = employe(matricule);
        List<TacheIntegration> taches = repository.findByEmployeIdAndType(e.getId(), type);
        if (taches.isEmpty()) {
            throw new BusinessException("Aucune liste " + type + " pour cet employé.");
        }
        long restantes = taches.stream().filter(t -> !t.isFaite()).count();
        if (restantes > 0) {
            throw new BusinessException(restantes + " tâche(s) restent à faire avant la clôture.");
        }
        if (clotureRepository.findByEmployeIdAndType(e.getId(), type).isPresent()) {
            throw new BusinessException("Ce processus est déjà clôturé.");
        }
        com.grhmobile.entity.ClotureIntegration c = new com.grhmobile.entity.ClotureIntegration();
        c.setEmploye(e);
        c.setType(type);
        c.setCloturePar(authenticatedUserService.currentUser());
        c.setCommentaire(commentaire);
        clotureRepository.save(c);
        return liste(matricule);
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
    public Map<String, Object> marquer(Long id, Map<String, Object> body) {
        TacheIntegration t = repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Tâche introuvable."));
        if (clotureRepository.findByEmployeIdAndType(t.getEmploye().getId(), t.getType()).isPresent()) {
            throw new BusinessException("Ce processus est clôturé : ses tâches ne sont plus modifiables.");
        }
        if (body.containsKey("faite")) {
            boolean faite = Boolean.TRUE.equals(body.get("faite"));
            t.setFaite(faite);
            t.setFaitePar(faite ? authenticatedUserService.currentUser() : null);
            t.setFaiteLe(faite ? OffsetDateTime.now() : null);
        }
        if (body.containsKey("responsable")) {
            t.setResponsable(texte(body.get("responsable"), 200));
        }
        if (body.containsKey("commentaire")) {
            t.setCommentaire(texte(body.get("commentaire"), 2000));
        }
        if (body.containsKey("echeance")) {
            String v = texte(body.get("echeance"), 10);
            try {
                t.setEcheance(v == null ? null : LocalDate.parse(v));
            } catch (Exception ex) {
                throw new BusinessException("Échéance invalide (format AAAA-MM-JJ).");
            }
        }
        repository.save(t);
        return toMap(t);
    }

    private static String texte(Object v, int max) {
        if (v == null || String.valueOf(v).isBlank()) {
            return null;
        }
        String s = String.valueOf(v).trim();
        return s.length() > max ? s.substring(0, max) : s;
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
        m.put("responsable", t.getResponsable());
        m.put("commentaire", t.getCommentaire());
        m.put("faitePar", t.getFaitePar() != null ? t.getFaitePar().getPrenom() + " " + t.getFaitePar().getNom() : null);
        m.put("faiteLe", t.getFaiteLe() != null ? t.getFaiteLe().toString() : null);
        return m;
    }
}
