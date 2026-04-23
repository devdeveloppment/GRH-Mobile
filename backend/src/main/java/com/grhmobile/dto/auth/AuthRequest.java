package com.grhmobile.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record AuthRequest(
    @NotBlank(message = "L'e-mail est obligatoire.")
    @Email(message = "L'e-mail doit être valide.")
    String email,
    @NotBlank(message = "Le mot de passe est obligatoire.")
    String password
) {
}
