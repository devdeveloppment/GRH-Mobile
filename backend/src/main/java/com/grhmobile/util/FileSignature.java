package com.grhmobile.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import com.grhmobile.exception.BusinessException;

import org.springframework.web.multipart.MultipartFile;

/**
 * Détection du type réel d'un fichier par son contenu (signature binaire), indépendamment
 * de son extension ou du Content-Type déclaré par le client.
 */
public final class FileSignature {

    private static final int MAX_ENTREES_ZIP = 2000;

    private FileSignature() {
    }

    /**
     * Renvoie l'extension correspondant au contenu réel, si reconnue :
     * ".pdf", ".png", ".jpg", ".docx", ".xlsx", ou ".ole" (ancien format Office .doc/.xls).
     */
    public static Optional<String> detect(MultipartFile file) {
        byte[] head = new byte[8];
        int read;
        try (InputStream in = file.getInputStream()) {
            read = in.readNBytes(head, 0, head.length);
        } catch (IOException e) {
            return Optional.empty();
        }
        if (read >= 4 && head[0] == '%' && head[1] == 'P' && head[2] == 'D' && head[3] == 'F') {
            return Optional.of(".pdf");
        }
        if (read >= 8 && (head[0] & 0xFF) == 0x89 && head[1] == 'P' && head[2] == 'N' && head[3] == 'G') {
            return Optional.of(".png");
        }
        if (read >= 3 && (head[0] & 0xFF) == 0xFF && (head[1] & 0xFF) == 0xD8 && (head[2] & 0xFF) == 0xFF) {
            return Optional.of(".jpg");
        }
        if (read >= 8 && (head[0] & 0xFF) == 0xD0 && (head[1] & 0xFF) == 0xCF && (head[2] & 0xFF) == 0x11
            && (head[3] & 0xFF) == 0xE0 && (head[4] & 0xFF) == 0xA1 && (head[5] & 0xFF) == 0xB1
            && (head[6] & 0xFF) == 0x1A && (head[7] & 0xFF) == 0xE1) {
            return Optional.of(".ole");
        }
        if (read >= 4 && head[0] == 'P' && head[1] == 'K' && head[2] == 3 && head[3] == 4) {
            return officeOpenXml(file);
        }
        return Optional.empty();
    }

    /** Un .docx / .xlsx est une archive ZIP contenant [Content_Types].xml et word/ ou xl/. */
    private static Optional<String> officeOpenXml(MultipartFile file) {
        boolean contentTypes = false;
        boolean word = false;
        boolean excel = false;
        int n = 0;
        try (ZipInputStream zip = new ZipInputStream(file.getInputStream())) {
            ZipEntry e;
            while ((e = zip.getNextEntry()) != null && n++ < MAX_ENTREES_ZIP) {
                String name = e.getName();
                contentTypes |= name.equals("[Content_Types].xml");
                word |= name.startsWith("word/");
                excel |= name.startsWith("xl/");
            }
        } catch (IOException | IllegalArgumentException e) {
            return Optional.empty();
        }
        if (contentTypes && word) {
            return Optional.of(".docx");
        }
        if (contentTypes && excel) {
            return Optional.of(".xlsx");
        }
        return Optional.empty();
    }

    /**
     * Vérifie un fichier déposé et renvoie l'extension à utiliser pour le stockage.
     * Refuse : fichier vide ou trop gros, nom suspect (chemin, caractères de contrôle),
     * extension non autorisée, et contenu réel ne correspondant pas à l'extension
     * (par exemple un exécutable renommé en .pdf).
     */
    public static String verifier(MultipartFile file, Set<String> extensionsAutorisees, long tailleMax) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Aucun fichier reçu.");
        }
        if (file.getSize() > tailleMax) {
            throw new BusinessException("Le fichier ne doit pas dépasser " + (tailleMax / (1024 * 1024)) + " Mo.");
        }
        String nom = file.getOriginalFilename();
        if (nom == null || nom.isBlank() || nom.length() > 255 || nom.contains("/") || nom.contains("\\")
            || nom.contains("..") || nom.chars().anyMatch(c -> c < 0x20)) {
            throw new BusinessException("Nom de fichier invalide.");
        }
        String ext = nom.contains(".") ? nom.substring(nom.lastIndexOf('.')).toLowerCase(Locale.ROOT) : "";
        if (!extensionsAutorisees.contains(ext)) {
            throw new BusinessException("Format non accepté.");
        }
        String reel = detect(file).orElseThrow(() ->
            new BusinessException("Le contenu du fichier ne correspond à aucun format accepté."));
        boolean concorde = switch (ext) {
            case ".jpeg", ".jpg" -> reel.equals(".jpg");
            case ".doc", ".xls" -> reel.equals(".ole");
            default -> reel.equals(ext);
        };
        if (!concorde) {
            throw new BusinessException("Le contenu du fichier ne correspond pas à son extension.");
        }
        return ext.equals(".jpeg") ? ".jpg" : ext;
    }

    /** Nom d'origine nettoyé, pour l'affichage uniquement (jamais utilisé comme chemin). */
    public static String nomAffichable(MultipartFile file, String defaut) {
        String nom = file.getOriginalFilename();
        if (nom == null || nom.isBlank()) {
            return defaut;
        }
        String propre = nom.replaceAll("[\\p{Cntrl}/\\\\]", "_").trim();
        return propre.length() > 200 ? propre.substring(0, 200) : propre;
    }
}
