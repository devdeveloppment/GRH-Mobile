package com.grhmobile.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Optional;

import org.springframework.web.multipart.MultipartFile;

/**
 * Détection du type réel d'un fichier par ses premiers octets (signature), indépendamment
 * de son extension ou du Content-Type déclaré par le client.
 */
public final class FileSignature {

    private FileSignature() {
    }

    /** Renvoie l'extension correspondant au contenu réel (".pdf", ".png", ".jpg"), si reconnue. */
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
        return Optional.empty();
    }
}
