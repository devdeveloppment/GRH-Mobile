package com.grhmobile.dto.qrcode;

import java.time.LocalDateTime;

public record QrScanResponse(
    String nomComplet,
    String matricule,
    String type,       // "ENTREE" ou "SORTIE"
    LocalDateTime heure,
    String statut      // toujours "OK"
) {
    public static QrScanResponse ok(String nomComplet, String matricule, String type, LocalDateTime heure) {
        return new QrScanResponse(nomComplet, matricule, type, heure, "OK");
    }
}
