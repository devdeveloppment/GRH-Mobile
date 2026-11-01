package com.grhmobile.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import com.grhmobile.audit.Auditable;
import com.grhmobile.dto.employee.DocumentDto;
import com.grhmobile.entity.Document;
import com.grhmobile.entity.Employe;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.DocumentRepository;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/** Coffre-fort documentaire des dossiers du personnel (stockage disque local). */
@Service
public class DocumentService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".pdf", ".doc", ".docx", ".jpg", ".jpeg", ".png", ".xls", ".xlsx");
    private static final long MAX_BYTES = 10L * 1024 * 1024;

    private final DocumentRepository documentRepository;
    private final EmployeeService employeeService;
    private final Path storageDir;

    public DocumentService(
        DocumentRepository documentRepository,
        EmployeeService employeeService,
        @Value("${app.documents-dir:uploads/documents}") String storageDir
    ) {
        this.documentRepository = documentRepository;
        this.employeeService = employeeService;
        this.storageDir = Paths.get(storageDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.storageDir);
        } catch (IOException exception) {
            throw new IllegalStateException("Impossible de créer le répertoire des documents.", exception);
        }
    }

    @Auditable(action = "UPLOAD_DOCUMENT", entite = "Document")
    @Transactional
    public DocumentDto upload(String matricule, MultipartFile file, String nom, String type) {
        String extension = com.grhmobile.util.FileSignature.verifier(file, ALLOWED_EXTENSIONS, MAX_BYTES);
        String originalName = com.grhmobile.util.FileSignature.nomAffichable(file, "document" + extension);

        Employe employe = employeeService.findByMatricule(matricule);
        String storedName = UUID.randomUUID() + extension;
        try {
            Files.copy(file.getInputStream(), storageDir.resolve(storedName), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exception) {
            throw new IllegalStateException("Erreur lors de l'enregistrement du document.", exception);
        }

        Document document = new Document();
        document.setEmploye(employe);
        document.setNom(nom != null && !nom.isBlank() ? nom.trim() : originalName);
        document.setType(type != null && !type.isBlank() ? type.trim().toUpperCase(Locale.ROOT) : extension.substring(1).toUpperCase(Locale.ROOT));
        document.setTailleKo((int) Math.max(1, file.getSize() / 1024));
        document.setUrl(storedName);
        return DocumentDto.fromEntity(documentRepository.save(document));
    }

    @Transactional(readOnly = true)
    public Document findById(Long id) {
        return documentRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Document introuvable."));
    }

    /** Matricule du propriétaire, utilisé pour le contrôle d'accès. */
    @Transactional(readOnly = true)
    public String ownerMatricule(Long id) {
        return documentRepository.findById(id).map(d -> d.getEmploye().getMatricule()).orElse("");
    }

    public Resource load(Document document) {
        String storedName = document.getUrl();
        if (storedName == null || storedName.isBlank() || storedName.contains("/") || storedName.contains("\\")) {
            throw new ResourceNotFoundException("Le fichier de ce document n'est pas disponible.");
        }
        Path path = storageDir.resolve(storedName).normalize();
        if (!path.startsWith(storageDir) || !Files.isReadable(path)) {
            throw new ResourceNotFoundException("Le fichier de ce document n'est pas disponible.");
        }
        return new FileSystemResource(path);
    }

    @Auditable(action = "DELETE_DOCUMENT", entite = "Document")
    @Transactional
    public void delete(Long id) {
        Document document = findById(id);
        documentRepository.delete(document);
        try {
            String storedName = document.getUrl();
            if (storedName != null && !storedName.contains("/") && !storedName.contains("\\")) {
                Files.deleteIfExists(storageDir.resolve(storedName));
            }
        } catch (IOException ignored) {
            // la ligne est supprimée ; un fichier orphelin n'est pas bloquant
        }
    }
}
