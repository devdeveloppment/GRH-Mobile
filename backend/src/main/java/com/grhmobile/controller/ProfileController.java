package com.grhmobile.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.grhmobile.entity.Utilisateur;
import com.grhmobile.repository.UtilisateurRepository;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.upload.dir:uploads/photos}")
    private String uploadDir;

    public ProfileController(UtilisateurRepository utilisateurRepository, PasswordEncoder passwordEncoder) {
        this.utilisateurRepository = utilisateurRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Upload photo de profil pour l'utilisateur connecté
     * POST /api/profile/photo
     *
     * @param photo fichier multipart
     * @param authentication authentification Spring Security
     * @return { "photoUrl": String }
     */
    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadPhoto(
            @RequestParam("photo") MultipartFile photo,
            Authentication authentication) {

        try {
            // Vérifier que l'utilisateur est authentifié
            if (authentication == null || !authentication.isAuthenticated()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Utilisateur non authentifié"));
            }

            String username = authentication.getName();
            Utilisateur user = utilisateurRepository.findByEmailIgnoreCase(username)
                    .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));

            // Vérifier le fichier
            if (photo.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Fichier vide"));
            }

            // Valider le type MIME
            String contentType = photo.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Le fichier doit être une image"));
            }

            // Créer le répertoire s'il n'existe pas
            Path uploadPath = Paths.get(uploadDir);
            Files.createDirectories(uploadPath);

            // Sauvegarder le fichier : {uploadDir}/{userId}.jpg
            String filename = user.getId() + ".jpg";
            Path filePath = uploadPath.resolve(filename);
            Files.write(filePath, photo.getBytes());

            // Mettre à jour photoUrl de l'utilisateur
            String photoUrl = "/uploads/photos/" + filename;
            user.setPhotoUrl(photoUrl);
            utilisateurRepository.save(user);

            return ResponseEntity.ok(Map.of(
                    "photoUrl", photoUrl,
                    "message", "Photo uploadée avec succès"
            ));

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Erreur lors de l'upload: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Changer le mot de passe
     * PUT /api/profile/password
     */
    @PutMapping("/password")
    public ResponseEntity<Map<String, Object>> changePassword(
            @RequestBody Map<String, String> body,
            Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Utilisateur non authentifié"));
        }
        String currentPassword = body.get("currentPassword");
        String newPassword = body.get("newPassword");
        if (currentPassword == null || newPassword == null || newPassword.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Paramètres invalides"));
        }
        Utilisateur user = utilisateurRepository.findByEmailIgnoreCase(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));
        if (!passwordEncoder.matches(currentPassword, user.getMotDePasse())) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(Map.of("error", "Mot de passe actuel incorrect"));
        }
        user.setMotDePasse(passwordEncoder.encode(newPassword));
        utilisateurRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Mot de passe modifié avec succès"));
    }

    /**
     * Supprimer la photo de profil
     * DELETE /api/profile/photo
     */
    @DeleteMapping("/photo")
    public ResponseEntity<Map<String, Object>> deletePhoto(Authentication authentication) {
        try {
            if (authentication == null || !authentication.isAuthenticated()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Utilisateur non authentifié"));
            }

            String username = authentication.getName();
            Utilisateur user = utilisateurRepository.findByEmailIgnoreCase(username)
                    .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));

            // Supprimer le fichier si existe
            if (user.getPhotoUrl() != null) {
                String filename = user.getId() + ".jpg";
                Path filePath = Paths.get(uploadDir, filename);
                Files.deleteIfExists(filePath);
            }

            // Réinitialiser photoUrl
            user.setPhotoUrl(null);
            utilisateurRepository.save(user);

            return ResponseEntity.ok(Map.of("message", "Photo supprimée avec succès"));

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Erreur lors de la suppression: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
