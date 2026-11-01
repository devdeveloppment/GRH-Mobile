package com.grhmobile.service;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.grhmobile.audit.Auditable;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.NoteFrais;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.NoteFraisRepository;
import com.grhmobile.security.AuthenticatedUserService;
import com.grhmobile.security.AccessControlService;
import com.grhmobile.util.FileSignature;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/** Notes de frais : soumission, validation (jamais par le demandeur), remboursement déclaratif. */
@Service
public class NoteFraisService {

    private static final long MAX_BYTES = 5L * 1024 * 1024;

    private final NoteFraisRepository repository;
    private final EmployeeService employeeService;
    private final AuthenticatedUserService authenticatedUserService;
    private final NotificationService notificationService;
    private final AccessControlService acl;
    private final Path dir;

    public NoteFraisService(NoteFraisRepository repository, EmployeeService employeeService,
                            AuthenticatedUserService authenticatedUserService, NotificationService notificationService,
                            AccessControlService acl, @Value("${app.frais-dir:uploads/frais}") String dir) {
        this.repository = repository;
        this.employeeService = employeeService;
        this.authenticatedUserService = authenticatedUserService;
        this.notificationService = notificationService;
        this.acl = acl;
        this.dir = Paths.get(dir).toAbsolutePath().normalize();
    }

    public boolean peutGerer() {
        return acl.can("MANAGE_PAIE") || acl.can("MANAGE_LEAVES");
    }

    @Auditable(action = "SUBMIT_NOTE_FRAIS", entite = "NoteFrais")
    @Transactional
    public Map<String, Object> soumettre(LocalDate dateDepense, String categorie, BigDecimal montant,
                                         String description, MultipartFile justificatif) {
        Employe employe = employeeService.findByUserId(authenticatedUserService.currentUser().getId());
        if (dateDepense == null || dateDepense.isAfter(LocalDate.now())) {
            throw new BusinessException("La date de la dépense est obligatoire et ne peut pas être future.");
        }
        if (categorie == null || !NoteFrais.CATEGORIES.contains(categorie)) {
            throw new BusinessException("Catégorie attendue : " + NoteFrais.CATEGORIES);
        }
        if (montant == null || montant.signum() <= 0) {
            throw new BusinessException("Le montant doit être strictement positif.");
        }
        if (description == null || description.isBlank()) {
            throw new BusinessException("La description est obligatoire.");
        }
        NoteFrais n = new NoteFrais();
        n.setEmploye(employe);
        n.setDateDepense(dateDepense);
        n.setCategorie(categorie);
        n.setMontant(montant.setScale(2, java.math.RoundingMode.HALF_UP));
        n.setDescription(description.trim());
        if (justificatif != null && !justificatif.isEmpty()) {
            stocker(n, justificatif);
        }
        repository.save(n);
        return toMap(n);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> mesNotes() {
        Employe employe = employeeService.findByUserId(authenticatedUserService.currentUser().getId());
        List<Map<String, Object>> items = repository.findByEmployeIdOrderByCreatedAtDesc(employe.getId())
            .stream().map(this::toMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> toutes(String statut) {
        List<NoteFrais> list = statut == null || statut.isBlank() ? repository.findAllByOrderByCreatedAtDesc()
            : repository.findByStatutOrderByCreatedAtDesc(statut);
        List<Map<String, Object>> items = list.stream().map(this::toMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    @Auditable(action = "APPROVE_NOTE_FRAIS", entite = "NoteFrais")
    @Transactional
    public Map<String, Object> approuver(Long id) {
        NoteFrais n = decider(id, "SOUMISE");
        n.setStatut("APPROUVEE");
        repository.save(n);
        notifier(n, "Note de frais approuvée", "Votre note de frais de " + n.getMontant() + " " + n.getDevise() + " a été approuvée.");
        return toMap(n);
    }

    @Auditable(action = "REJECT_NOTE_FRAIS", entite = "NoteFrais")
    @Transactional
    public Map<String, Object> refuser(Long id, String commentaire) {
        if (commentaire == null || commentaire.isBlank()) {
            throw new BusinessException("Un motif de refus est obligatoire.");
        }
        NoteFrais n = decider(id, "SOUMISE");
        n.setStatut("REFUSEE");
        n.setCommentaire(commentaire.trim());
        repository.save(n);
        notifier(n, "Note de frais refusée", "Votre note de frais a été refusée : " + commentaire.trim());
        return toMap(n);
    }

    /** Déclaration manuelle d'un remboursement déjà effectué hors application (aucun paiement ici). */
    @Auditable(action = "DECLARE_REMBOURSEMENT_NOTE_FRAIS", entite = "NoteFrais")
    @Transactional
    public Map<String, Object> declarerRembourse(Long id, String reference) {
        if (reference == null || reference.isBlank()) {
            throw new BusinessException("La référence du remboursement (virement, mobile money, caisse) est obligatoire.");
        }
        NoteFrais n = decider(id, "APPROUVEE");
        n.setStatut("REMBOURSEE");
        n.setReferenceRemboursement(reference.trim());
        n.setDateRemboursement(OffsetDateTime.now());
        repository.save(n);
        return toMap(n);
    }

    @Transactional(readOnly = true)
    public NoteFrais chargerPourJustificatif(Long id) {
        NoteFrais n = repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Note de frais introuvable."));
        Utilisateur current = authenticatedUserService.currentUser();
        boolean proprietaire = n.getEmploye().getUtilisateur() != null
            && n.getEmploye().getUtilisateur().getId().equals(current.getId());
        if (!proprietaire && !peutGerer()) {
            throw new org.springframework.security.access.AccessDeniedException("Accès refusé.");
        }
        if (n.getJustificatifPath() == null) {
            throw new ResourceNotFoundException("Aucun justificatif.");
        }
        return n;
    }

    public Resource charger(NoteFrais n) {
        try {
            Path path = dir.resolve(n.getJustificatifPath()).normalize();
            if (!path.startsWith(dir)) {
                throw new ResourceNotFoundException("Fichier introuvable.");
            }
            Resource r = new UrlResource(path.toUri());
            if (!r.exists()) {
                throw new ResourceNotFoundException("Fichier introuvable.");
            }
            return r;
        } catch (java.net.MalformedURLException e) {
            throw new ResourceNotFoundException("Fichier introuvable.");
        }
    }

    private NoteFrais decider(Long id, String statutAttendu) {
        if (!peutGerer()) {
            throw new org.springframework.security.access.AccessDeniedException("Accès refusé.");
        }
        NoteFrais n = repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Note de frais introuvable."));
        Utilisateur current = authenticatedUserService.currentUser();
        if (n.getEmploye().getUtilisateur() != null && n.getEmploye().getUtilisateur().getId().equals(current.getId())) {
            throw new org.springframework.security.access.AccessDeniedException("Vous ne pouvez pas traiter votre propre note de frais.");
        }
        if (!statutAttendu.equals(n.getStatut())) {
            throw new BusinessException("Action impossible : la note est au statut " + n.getStatut() + ".");
        }
        n.setDecideur(current);
        n.setDateDecision(OffsetDateTime.now());
        return n;
    }

    private void stocker(NoteFrais n, MultipartFile file) {
        if (file.getSize() > MAX_BYTES) {
            throw new BusinessException("Le justificatif ne doit pas dépasser 5 Mo.");
        }
        String ext = FileSignature.detect(file)
            .orElseThrow(() -> new BusinessException("Justificatif refusé : seuls les PDF, PNG et JPEG réels sont acceptés."));
        try {
            Files.createDirectories(dir);
            String stored = UUID.randomUUID() + ext;
            Files.copy(file.getInputStream(), dir.resolve(stored), StandardCopyOption.REPLACE_EXISTING);
            n.setJustificatifPath(stored);
            String original = file.getOriginalFilename();
            n.setJustificatifNom(original == null || original.isBlank() ? "justificatif" + ext
                : original.replaceAll("[\\\\/:*?\"<>|]", "_"));
        } catch (IOException e) {
            throw new IllegalStateException("Enregistrement du justificatif impossible.", e);
        }
    }

    private void notifier(NoteFrais n, String titre, String message) {
        if (n.getEmploye().getUtilisateur() != null) {
            notificationService.create(n.getEmploye().getUtilisateur().getId(), titre, message, "FRAIS", "/employee/home");
        }
    }

    private Map<String, Object> toMap(NoteFrais n) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId());
        m.put("matricule", n.getEmploye().getMatricule());
        m.put("employe", n.getEmploye().getPrenom() + " " + n.getEmploye().getNom());
        m.put("dateDepense", n.getDateDepense().toString());
        m.put("categorie", n.getCategorie());
        m.put("montant", n.getMontant());
        m.put("devise", n.getDevise());
        m.put("description", n.getDescription());
        m.put("justificatif", n.getJustificatifPath() != null);
        m.put("statut", n.getStatut());
        m.put("commentaire", n.getCommentaire());
        m.put("referenceRemboursement", n.getReferenceRemboursement());
        m.put("dateDecision", n.getDateDecision() != null ? n.getDateDecision().toString() : null);
        return m;
    }
}
