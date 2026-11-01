package com.grhmobile.dto.qrcode;

import com.grhmobile.entity.EmployeQrCode;

import java.time.OffsetDateTime;

public record QrCodeResponse(
    Long id,
    Long employeId,
    String matricule,
    String nomComplet,
    String token,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt,
    java.time.Instant expiresAt
) {
    /** @param signedToken jeton dynamique signé (valable quelques dizaines de secondes) */
    public static QrCodeResponse fromEntity(EmployeQrCode qr, String signedToken, java.time.Instant expiresAt) {
        return new QrCodeResponse(
            qr.getId(),
            qr.getEmploye().getId(),
            qr.getEmploye().getMatricule(),
            qr.getEmploye().getPrenom() + " " + qr.getEmploye().getNom(),
            signedToken,
            qr.getCreatedAt(),
            qr.getUpdatedAt(),
            expiresAt
        );
    }
}
