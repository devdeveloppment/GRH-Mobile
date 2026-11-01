package com.grhmobile.controller;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;

import com.grhmobile.entity.NoteFrais;
import com.grhmobile.service.NoteFraisService;

import org.springframework.core.io.Resource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/notes-frais")
public class NoteFraisController {

    private final NoteFraisService service;

    public NoteFraisController(NoteFraisService service) {
        this.service = service;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> soumettre(
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateDepense,
        @RequestParam String categorie,
        @RequestParam BigDecimal montant,
        @RequestParam String description,
        @RequestPart(value = "justificatif", required = false) MultipartFile justificatif) {
        return service.soumettre(dateDepense, categorie, montant, description, justificatif);
    }

    @GetMapping("/me")
    public Map<String, Object> mesNotes() {
        return service.mesNotes();
    }

    @GetMapping
    @PreAuthorize("@acl.can('MANAGE_PAIE') or @acl.can('MANAGE_LEAVES')")
    public Map<String, Object> toutes(@RequestParam(required = false) String statut) {
        return service.toutes(statut);
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("@acl.can('MANAGE_PAIE') or @acl.can('MANAGE_LEAVES')")
    public Map<String, Object> approuver(@PathVariable Long id) {
        return service.approuver(id);
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("@acl.can('MANAGE_PAIE') or @acl.can('MANAGE_LEAVES')")
    public Map<String, Object> refuser(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return service.refuser(id, body.get("commentaire"));
    }

    @PostMapping("/{id}/remboursement")
    @PreAuthorize("@acl.can('MANAGE_PAIE')")
    public Map<String, Object> declarerRembourse(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return service.declarerRembourse(id, body.get("reference"));
    }

    @GetMapping("/{id}/justificatif")
    public ResponseEntity<Resource> justificatif(@PathVariable Long id) {
        NoteFrais n = service.chargerPourJustificatif(id);
        Resource r = service.charger(n);
        MediaType type = MediaTypeFactory.getMediaType(n.getJustificatifPath()).orElse(MediaType.APPLICATION_OCTET_STREAM);
        return ResponseEntity.ok().contentType(type)
            .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename(n.getJustificatifNom(), java.nio.charset.StandardCharsets.UTF_8).build().toString())
            .body(r);
    }
}
