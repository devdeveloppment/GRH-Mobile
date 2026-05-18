package com.grhmobile.controller;

import com.grhmobile.dto.recrutement.*;
import com.grhmobile.service.RecrutementService;

import jakarta.validation.Valid;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class RecrutementController {

    private final RecrutementService recrutementService;

    public RecrutementController(RecrutementService recrutementService) {
        this.recrutementService = recrutementService;
    }

    // ─── Offres ───────────────────────────────────────────────────────────────

    @GetMapping("/offres")
    public Map<String, Object> listOffres(@RequestParam(required = false) String statut) {
        return recrutementService.listOffres(statut);
    }

    @PostMapping("/offres")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public OffreResponse createOffre(@Valid @RequestBody OffreRequest request) {
        return recrutementService.createOffre(request);
    }

    @PutMapping("/offres/{id}/statut")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public OffreResponse updateStatutOffre(@PathVariable Long id, @RequestParam String statut) {
        return recrutementService.updateStatutOffre(id, statut);
    }

    // ─── Candidatures ─────────────────────────────────────────────────────────

    @GetMapping("/offres/{offreId}/candidatures")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public Map<String, Object> listCandidatures(@PathVariable Long offreId) {
        return recrutementService.listCandidatures(offreId);
    }

    /** Candidature JSON simple (sans fichier) — public */
    @PostMapping("/offres/{offreId}/candidatures")
    @ResponseStatus(HttpStatus.CREATED)
    public CandidatureResponse postuler(@PathVariable Long offreId,
                                        @Valid @RequestBody CandidatureRequest request) {
        return recrutementService.postuler(offreId, request);
    }

    /** Candidature multipart avec CV — public */
    @PostMapping(value = "/offres/{offreId}/candidatures/upload",
                 consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public CandidatureResponse postulerAvecCv(
            @PathVariable Long offreId,
            @RequestParam String nom,
            @RequestParam String prenom,
            @RequestParam String email,
            @RequestParam(required = false) String telephone,
            @RequestParam(required = false) String lettreMotivation,
            @RequestParam(required = false) MultipartFile cv) {
        return recrutementService.postulerAvecCv(offreId, nom, prenom, email,
                telephone, lettreMotivation, cv);
    }

    /** Télécharger le CV d'une candidature */
    @GetMapping("/candidatures/{id}/cv")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public ResponseEntity<Resource> downloadCv(@PathVariable Long id) {
        Resource resource = recrutementService.downloadCv(id);
        String filename = resource.getFilename() != null ? resource.getFilename() : "cv.pdf";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }

    @PutMapping("/candidatures/{id}/statut")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public CandidatureResponse updateStatutCandidature(
        @PathVariable Long id,
        @RequestParam String statut,
        @RequestParam(required = false) Integer note,
        @RequestParam(required = false) String commentaire
    ) {
        return recrutementService.updateStatutCandidature(id, statut, note, commentaire);
    }

    /** Embaucher un candidat — crée l'employé + compte utilisateur */
    @PostMapping("/candidatures/{id}/embaucher")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public Map<String, Object> embaucher(
            @PathVariable Long id,
            @RequestParam(required = false) String poste,
            @RequestParam(required = false) String service,
            @RequestParam(required = false, defaultValue = "CDI") String typeContrat,
            @RequestParam(required = false) BigDecimal salaire) {
        return recrutementService.embaucher(id, poste, service, typeContrat, salaire);
    }

    // ─── Entretiens ───────────────────────────────────────────────────────────

    @GetMapping("/candidatures/{candidatureId}/entretiens")
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public List<EntretienResponse> listEntretiens(@PathVariable Long candidatureId) {
        return recrutementService.listEntretiens(candidatureId);
    }

    @PostMapping("/candidatures/{candidatureId}/entretiens")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','HR_ADMIN','RH_MANAGER','RECRUITER')")
    public EntretienResponse planifierEntretien(@PathVariable Long candidatureId,
                                                @Valid @RequestBody EntretienRequest request) {
        return recrutementService.planifierEntretien(candidatureId, request);
    }
}
