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

    public String[] storeCv(MultipartFile file) {
        String originalName = file.getOriginalFilename();
        if (originalName == null || originalName.isBlank()) {
            throw new BusinessException("Nom de fichier invalide.");
        }
        String ext = originalName.contains(".")
                ? originalName.substring(originalName.lastIndexOf('.'))
                : "";
        if (!ext.equalsIgnoreCase(".pdf") && !ext.equalsIgnoreCase(".doc")
                && !ext.equalsIgnoreCase(".docx")) {
            throw new BusinessException("Format non accepté. Utilisez PDF, DOC ou DOCX.");
        }
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new BusinessException("Le fichier ne doit pas dépasser 5 Mo.");
        }
        String storedName = UUID.randomUUID() + ext;
        Path target = uploadDir.resolve(storedName);
        try {
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Erreur lors de la sauvegarde du fichier.", e);
        }
        return new String[]{target.toString(), originalName};
    }

    public Resource loadCv(String filePath) {
        try {
            Path path = Paths.get(filePath).normalize();
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
