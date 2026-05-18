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
    OffsetDateTime updatedAt
) {
    public static QrCodeResponse fromEntity(EmployeQrCode qr) {
        return new QrCodeResponse(
            qr.getId(),
            qr.getEmploye().getId(),
            qr.getEmploye().getMatricule(),
            qr.getEmploye().getPrenom() + " " + qr.getEmploye().getNom(),
            qr.getToken(),
            qr.getCreatedAt(),
            qr.getUpdatedAt()
        );
    }
}
