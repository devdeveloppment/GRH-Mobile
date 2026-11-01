package com.grhmobile.service;

import com.grhmobile.audit.Auditable;
import com.grhmobile.dto.employee.EmployeeRequest;
import com.grhmobile.dto.employee.EmployeeResponse;
import com.grhmobile.dto.recrutement.*;
import com.grhmobile.entity.*;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.*;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
public class RecrutementService {

    private static final java.util.List<String> STATUTS_CANDIDATURE =
        java.util.List.of("RECUE", "PRESELECTIONNE", "ENTRETIEN", "RETENU", "REFUSE");
    private static final java.util.List<String> STATUTS_OFFRE =
        java.util.List.of("BROUILLON", "PUBLIEE", "FERMEE", "POURVUE", "ANNULEE");

    private final OffreEmploiRepository offreRepository;
    private final CandidatureRepository candidatureRepository;
    private final EntretienRepository entretienRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final PosteService posteService;
    private final DepartementService departementService;
    private final AuthenticatedUserService authService;
    private final EmployeeService employeeService;
    private final FileStorageService fileStorageService;

    public RecrutementService(OffreEmploiRepository offreRepository,
                               CandidatureRepository candidatureRepository,
                               EntretienRepository entretienRepository,
                               UtilisateurRepository utilisateurRepository,
                               PosteService posteService,
                               DepartementService departementService,
                               AuthenticatedUserService authService,
                               EmployeeService employeeService,
                               FileStorageService fileStorageService) {
        this.offreRepository = offreRepository;
        this.candidatureRepository = candidatureRepository;
        this.entretienRepository = entretienRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.posteService = posteService;
        this.departementService = departementService;
        this.authService = authService;
        this.employeeService = employeeService;
        this.fileStorageService = fileStorageService;
    }

    // ─── Offres ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public Map<String, Object> listOffres(String statut) {
        List<OffreResponse> items = (statut != null && !statut.isBlank()
            ? offreRepository.findByStatutOrderByCreatedAtDesc(statut.toUpperCase())
            : offreRepository.findAllByOrderByCreatedAtDesc())
            .stream()
            .map(OffreResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional(readOnly = true)
    public OffreResponse getOffrePubliee(Long id) {
        OffreEmploi offre = findOffreById(id);
        if (!"PUBLIEE".equals(offre.getStatut())) {
            throw new ResourceNotFoundException("Cette offre n'est plus disponible.");
        }
        return OffreResponse.fromEntity(offre);
    }

    @Transactional
    public OffreResponse createOffre(OffreRequest request) {
        OffreEmploi offre = new OffreEmploi();
        offre.setTitre(request.titre().trim());
        offre.setDescription(request.description());
        offre.setDateLimite(request.dateLimite());
        offre.setCreatedBy(authService.currentUser());

        Long posteId = request.posteId();
        offre.setPoste(posteId != null ? posteService.findById(posteId) : null);

        Long deptId = request.departementId();
        offre.setDepartement(deptId != null ? departementService.findById(deptId) : null);

        return OffreResponse.fromEntity(offreRepository.save(offre));
    }

    @Transactional
    public OffreResponse updateStatutOffre(Long id, String statut) {
        OffreEmploi offre = findOffreById(id);
        String nouveauStatut = statut == null ? "" : statut.trim().toUpperCase();
        if (!STATUTS_OFFRE.contains(nouveauStatut)) {
            throw new BusinessException("Statut d'offre inconnu : " + statut);
        }
        offre.setStatut(nouveauStatut);
        return OffreResponse.fromEntity(offreRepository.save(offre));
    }

    // ─── Candidatures ─────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public Map<String, Object> listCandidatures(Long offreId) {
        List<CandidatureResponse> items = candidatureRepository
            .findByOffreIdOrderByCreatedAtDesc(offreId)
            .stream()
            .map(CandidatureResponse::fromEntity)
            .toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional
    public CandidatureResponse postuler(Long offreId, CandidatureRequest request) {
        OffreEmploi offre = findOffreById(offreId);
        if (!"PUBLIEE".equals(offre.getStatut())) {
            throw new BusinessException("Cette offre n'accepte plus de candidatures.");
        }
        Candidature c = new Candidature();
        c.setOffre(offre);
        c.setNom(request.nom().trim());
        c.setPrenom(request.prenom().trim());
        c.setEmail(request.email().trim());
        c.setTelephone(request.telephone());
        c.setLettreMotivation(request.lettreMotivation());
        c.setCvUrl(request.cvUrl());
        return CandidatureResponse.fromEntity(candidatureRepository.save(c));
    }

    @Transactional
    public CandidatureResponse postulerAvecCv(Long offreId, String nom, String prenom,
                                              String email, String telephone,
                                              String lettreMotivation, MultipartFile cvFile) {
        OffreEmploi offre = findOffreById(offreId);
        if (!"PUBLIEE".equals(offre.getStatut())) {
            throw new BusinessException("Cette offre n'accepte plus de candidatures.");
        }
        Candidature c = new Candidature();
        c.setOffre(offre);
        c.setNom(nom.trim());
        c.setPrenom(prenom.trim());
        c.setEmail(email.trim());
        c.setTelephone(telephone);
        c.setLettreMotivation(lettreMotivation);

        if (cvFile != null && !cvFile.isEmpty()) {
            String[] stored = fileStorageService.storeCv(cvFile);
            c.setCvPath(stored[0]);
            c.setCvNomFichier(stored[1]);
        }
        return CandidatureResponse.fromEntity(candidatureRepository.save(c));
    }

    @Auditable(action = "HIRE_CANDIDATE", entite = "Candidature")
    @Transactional
    public Map<String, Object> embaucher(Long candidatureId, String poste, String service,
                                         String typeContrat, BigDecimal salaire) {
        Candidature c = findCandidatureById(candidatureId);
        if ("REFUSE".equals(c.getStatut())) {
            throw new BusinessException("Impossible d'embaucher un candidat refusé.");
        }
        EmployeeRequest req = new EmployeeRequest(
            c.getNom(),
            c.getPrenom(),
            null,
            null,
            null,
            c.getEmail(),
            c.getTelephone(),
            "ACTIF",
            LocalDate.now(),
            poste != null ? poste : c.getOffre().getTitre(),
            service != null ? service : "Non défini",
            typeContrat != null ? typeContrat : "CDI",
            null,
            null,
            null,
            salaire != null ? salaire : BigDecimal.ZERO,
            null,
            null,
            null
        );
        EmployeeResponse employe = employeeService.create(req);
        c.setStatut("RETENU");
        candidatureRepository.save(c);
        return Map.of("employe", employe, "matricule", employe.matricule());
    }

    public org.springframework.core.io.Resource downloadCv(Long candidatureId) {
        Candidature c = findCandidatureById(candidatureId);
        if (c.getCvPath() == null) {
            throw new BusinessException("Aucun CV téléchargé pour cette candidature.");
        }
        return fileStorageService.loadCv(c.getCvPath());
    }

    @Transactional
    public CandidatureResponse updateStatutCandidature(Long id, String statut, Integer note, String commentaire) {
        Candidature c = findCandidatureById(id);
        String nouveauStatut = statut == null ? "" : statut.trim().toUpperCase();
        if (!STATUTS_CANDIDATURE.contains(nouveauStatut)) {
            throw new BusinessException("Statut de candidature inconnu : " + statut
                + ". Valeurs possibles : " + String.join(", ", STATUTS_CANDIDATURE) + ".");
        }
        c.setStatut(nouveauStatut);
        if (note != null) c.setNote(note);
        if (commentaire != null) c.setCommentaire(commentaire);
        return CandidatureResponse.fromEntity(candidatureRepository.save(c));
    }

    // ─── Entretiens ───────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<EntretienResponse> listEntretiens(Long candidatureId) {
        return entretienRepository.findByCandidatureIdOrderByDateHeureAsc(candidatureId)
            .stream()
            .map(EntretienResponse::fromEntity)
            .toList();
    }

    @Transactional
    public EntretienResponse planifierEntretien(Long candidatureId, EntretienRequest request) {
        Candidature candidature = findCandidatureById(candidatureId);
        Entretien e = new Entretien();
        e.setCandidature(candidature);
        e.setDateHeure(request.dateHeure());
        e.setType(request.type() != null ? request.type().toUpperCase() : "TELEPHONE");

        Long intervieweurId = request.intervieweurId();
        if (intervieweurId != null) {
            utilisateurRepository.findById(intervieweurId).ifPresent(e::setIntervieweur);
        }

        // Passer la candidature en statut ENTRETIEN
        candidature.setStatut("ENTRETIEN");
        candidatureRepository.save(candidature);

        return EntretienResponse.fromEntity(entretienRepository.save(e));
    }

    private OffreEmploi findOffreById(Long id) {
        return offreRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Offre d'emploi introuvable."));
    }

    private Candidature findCandidatureById(Long id) {
        return candidatureRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Candidature introuvable."));
    }
}
