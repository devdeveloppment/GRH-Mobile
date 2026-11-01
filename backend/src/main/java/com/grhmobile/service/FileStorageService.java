package com.grhmobile.service;

import com.grhmobile.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageService {

    private final Path uploadDir;

    public FileStorageService(@Value("${app.upload-dir:uploads/cv}") String uploadDirPath) {
        this.uploadDir = Paths.get(uploadDirPath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.uploadDir);
        } catch (IOException e) {
            throw new RuntimeException("Impossible de créer le répertoire d'upload.", e);
        }
    }

    private static final java.util.Set<String> CV_EXTENSIONS = java.util.Set.of(".pdf", ".doc", ".docx");
    private static final long CV_MAX_BYTES = 5L * 1024 * 1024;

    /**
     * Enregistre un CV déposé publiquement. Le type réel est vérifié par signature binaire ;
     * le fichier est rangé dans le dossier de l'entreprise sous un nom aléatoire, sans exécution possible.
     */
    public String[] storeCv(MultipartFile file) {
        String ext = com.grhmobile.util.FileSignature.verifier(file, CV_EXTENSIONS, CV_MAX_BYTES);
        Long entrepriseId = com.grhmobile.tenant.TenantContext.get();
        if (entrepriseId == null || entrepriseId <= 0) {
            throw new BusinessException("Entreprise inconnue pour ce dépôt.");
        }
        Path dossier = uploadDir.resolve(String.valueOf(entrepriseId));
        Path target = dossier.resolve(UUID.randomUUID() + ext).normalize();
        try {
            Files.createDirectories(dossier);
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Erreur lors de la sauvegarde du fichier.", e);
        }
        return new String[]{target.toString(), com.grhmobile.util.FileSignature.nomAffichable(file, "cv" + ext)};
    }

    /** Ne sert que des fichiers situés sous le répertoire des CV (pas de chemin arbitraire). */
    public Resource loadCv(String filePath) {
        try {
            Path path = Paths.get(filePath).toAbsolutePath().normalize();
            if (!path.startsWith(uploadDir)) {
                throw new BusinessException("Fichier CV introuvable.");
            }
            Resource resource = new UrlResource(path.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                throw new BusinessException("Fichier CV introuvable.");
            }
            return resource;
        } catch (MalformedURLException e) {
            throw new BusinessException("Chemin du fichier invalide.");
        }
    }
}
