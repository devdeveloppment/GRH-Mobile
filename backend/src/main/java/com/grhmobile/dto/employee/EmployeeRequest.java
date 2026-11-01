package com.grhmobile.dto.employee;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record EmployeeRequest(
    @NotBlank(message = "Le nom est obligatoire.")
    String nom,
    @NotBlank(message = "Le prénom est obligatoire.")
    String prenom,
    LocalDate dateNaissance,
    String genre,
    String nationalite,
    @NotBlank(message = "L'e-mail est obligatoire.")
    @Email(message = "L'e-mail doit être valide.")
    String email,
    String telephone,
    String statut,
    LocalDate dateEmbauche,
    @NotBlank(message = "Le poste est obligatoire.")
    String poste,
    @NotBlank(message = "Le service est obligatoire.")
    String service,
    @NotBlank(message = "Le type de contrat est obligatoire.")
    String typeContrat,
    String adresse,
    LocalDate dateFin,
    String photoUrl,
    @NotNull(message = "Le salaire est obligatoire.")
    @jakarta.validation.constraints.PositiveOrZero(message = "Le salaire ne peut pas être négatif.")
    BigDecimal salaire,
    Long posteId,
    Long departementId,
    String managerMatricule
) {
}
