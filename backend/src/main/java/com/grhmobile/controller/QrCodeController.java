package com.grhmobile.controller;

import com.grhmobile.dto.qrcode.QrCodeResponse;
import com.grhmobile.service.QrCodeService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/qrcodes")
public class QrCodeController {

    private final QrCodeService qrCodeService;

    public QrCodeController(QrCodeService qrCodeService) {
        this.qrCodeService = qrCodeService;
    }

    /** Récupère (ou génère) le QR code de l'employé connecté. */
    @GetMapping("/me")
    public QrCodeResponse getMyQrCode() {
        return qrCodeService.getOrCreateMyQrCode();
    }

    /** Régénère un nouveau token pour l'employé connecté. */
    @PostMapping("/regenerate")
    public QrCodeResponse regenerate() {
        return qrCodeService.regenerateMyQrCode();
    }
}
