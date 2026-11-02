package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.service.ImportEmployesService;

import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** Import Excel des employés : modèle, aperçu sans écriture, import confirmé. */
@RestController
@RequestMapping("/api/import/employes")
@PreAuthorize("@acl.can('MANAGE_EMPLOYEES')")
public class ImportController {

    private final ImportEmployesService service;

    public ImportController(ImportEmployesService service) {
        this.service = service;
    }

    @GetMapping("/modele")
    public ResponseEntity<byte[]> modele() {
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename("modele_import_employes.xlsx").build().toString())
            .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .body(service.modele());
    }

    @PostMapping(value = "/apercu", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> apercu(@RequestParam("file") MultipartFile file) {
        return service.apercu(file);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> importer(@RequestParam("file") MultipartFile file) {
        return service.importer(file);
    }
}
