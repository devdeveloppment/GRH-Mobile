package com.grhmobile.dto.employee;

import java.time.LocalDate;

import com.grhmobile.entity.Employe;

public record EmployeeResponse(
    Long id,
    String matricule,
    String nom,
    String prenom,
    LocalDate dateNaissance,
    String genre,
    String nationalite,
    String email,
    String telephone,
    String statut,
    LocalDate dateEmbauche,
    String poste,
    String service,
    String typeContrat,
    String adresse,
    LocalDate dateFin,
    String photoUrl,
    Boolean presentAujourdHui,
    Double salaire,
    Long posteId,
    Long departementId,
    String departement,
    String managerMatricule,
    String managerNom,
    String motDePasseTemporaire
) {

    public static EmployeeResponse fromEntity(Employe employe, boolean presentAujourdHui) {
        return fromEntity(employe, presentAujourdHui, true, null);
    }

    /**
     * @param showSalary    false pour masquer le salaire aux profils non habilités
     * @param tempPassword  mot de passe temporaire, renvoyé uniquement à la création
     */
    public static EmployeeResponse fromEntity(Employe employe, boolean presentAujourdHui,
                                              boolean showSalary, String tempPassword) {
        Employe manager = employe.getManager();
        return new EmployeeResponse(
            employe.getId(),
            employe.getMatricule(),
            employe.getNom(),
            employe.getPrenom(),
            employe.getDateNaissance(),
            employe.getGenre() != null ? employe.getGenre().name() : null,
            employe.getNationalite(),
            employe.getEmail(),
            employe.getTelephone(),
            employe.getStatut(),
            employe.getDateEmbauche(),
            employe.getPoste(),
            employe.getService() != null ? employe.getService().getNom() : null,
            employe.getTypeContrat() != null ? employe.getTypeContrat().name() : "CDI",
            employe.getAdresse(),
            employe.getDateFinContrat(),
            employe.getPhotoUrl(),
            presentAujourdHui,
            showSalary && employe.getSalaireBrutBase() != null ? employe.getSalaireBrutBase().doubleValue() : null,
            employe.getPosteRef() != null ? employe.getPosteRef().getId() : null,
            employe.getDepartement() != null ? employe.getDepartement().getId() : null,
            employe.getDepartement() != null ? employe.getDepartement().getNom() : null,
            manager != null ? manager.getMatricule() : null,
            manager != null ? manager.getPrenom() + " " + manager.getNom() : null,
            tempPassword
        );
    }
}
