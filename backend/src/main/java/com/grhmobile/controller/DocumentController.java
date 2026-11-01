package com.grhmobile.controller;

import com.grhmobile.dto.employee.DocumentDto;
import com.grhmobile.entity.Document;
import com.grhmobile.service.DocumentService;

import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    @PostMapping(value = "/employees/{matricule}/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("@acl.canUploadDocument(#matricule)")
    public DocumentDto upload(
        @PathVariable String matricule,
        @RequestParam("file") MultipartFile file,
        @RequestParam(required = false) String nom,
        @RequestParam(required = false) String type
    ) {
        return documentService.upload(matricule, file, nom, type);
    }

    @GetMapping("/documents/{id}/download")
    @PreAuthorize("@acl.canViewDocument(#id)")
    public ResponseEntity<Resource> download(@PathVariable Long id) {
        Document document = documentService.findById(id);
        Resource resource = documentService.load(document);
        String storedName = document.getUrl();
        String extension = storedName.contains(".") ? storedName.substring(storedName.lastIndexOf('.')) : "";
        String fileName = document.getNom().endsWith(extension) ? document.getNom() : document.getNom() + extension;
        MediaType mediaType = MediaTypeFactory.getMediaType(storedName).orElse(MediaType.APPLICATION_OCTET_STREAM);
        return ResponseEntity.ok()
            .contentType(mediaType)
            .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename(fileName, java.nio.charset.StandardCharsets.UTF_8).build().toString())
            .body(resource);
    }

    @DeleteMapping("/documents/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasRole('RH_MANAGER')")
    public void delete(@PathVariable Long id) {
        documentService.delete(id);
    }
}
