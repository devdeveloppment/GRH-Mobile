package com.grhmobile.dto.qrcode;

import jakarta.validation.constraints.NotBlank;

public record QrScanRequest(
    @NotBlank(message = "Le token QR est obligatoire.")
    String token
) {
}
