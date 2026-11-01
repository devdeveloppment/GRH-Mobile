package com.grhmobile.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.persistence.*;

/** Paramètre de paie daté et sourcé (taux, plafond, montant). Aucune valeur légale n'est fournie par défaut. */
@Entity
@Table(name = "parametres_paie")
public class ParametrePaie extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String code;

    @Column(nullable = false, length = 200)
    private String libelle;

    @Column(nullable = false, precision = 18, scale = 6)
    private BigDecimal valeur;

    @Column(name = "date_debut", nullable = false)
    private LocalDate dateDebut;

    @Column(name = "date_fin")
    private LocalDate dateFin;

    @Column(columnDefinition = "TEXT")
    private String source;

    @Column(name = "valide_par", length = 200)
    private String validePar;

    @Column(name = "date_validation")
    private LocalDate dateValidation;

    /** BROUILLON, SOUMIS ou VALIDE. */
    @Column(nullable = false, length = 20)
    private String statut = "BROUILLON";

    @Column(name = "soumis_par")
    private Long soumisPar;

    @Column(name = "date_soumission")
    private java.time.OffsetDateTime dateSoumission;

    /** EXPERT_COMPTABLE, JURISTE ou AUTRE (déclaratif). */
    @Column(name = "qualite_validateur", length = 30)
    private String qualiteValidateur;

    @Column(name = "enregistre_par")
    private Long enregistrePar;

    /**
     * Validé = statut VALIDE, avec une source officielle et un validateur déclarés.
     * Tout autre paramètre est une simple hypothèse de simulation.
     */
    public boolean estValide() {
        return "VALIDE".equals(statut) && validePar != null && !validePar.isBlank()
            && source != null && !source.isBlank();
    }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    public Long getSoumisPar() { return soumisPar; }
    public void setSoumisPar(Long soumisPar) { this.soumisPar = soumisPar; }
    public java.time.OffsetDateTime getDateSoumission() { return dateSoumission; }
    public void setDateSoumission(java.time.OffsetDateTime dateSoumission) { this.dateSoumission = dateSoumission; }
    public String getQualiteValidateur() { return qualiteValidateur; }
    public void setQualiteValidateur(String qualiteValidateur) { this.qualiteValidateur = qualiteValidateur; }
    public Long getEnregistrePar() { return enregistrePar; }
    public void setEnregistrePar(Long enregistrePar) { this.enregistrePar = enregistrePar; }

    public boolean couvre(LocalDate date) {
        return !dateDebut.isAfter(date) && (dateFin == null || !dateFin.isBefore(date));
    }

    public Long getId() { return id; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
    public BigDecimal getValeur() { return valeur; }
    public void setValeur(BigDecimal valeur) { this.valeur = valeur; }
    public LocalDate getDateDebut() { return dateDebut; }
    public void setDateDebut(LocalDate dateDebut) { this.dateDebut = dateDebut; }
    public LocalDate getDateFin() { return dateFin; }
    public void setDateFin(LocalDate dateFin) { this.dateFin = dateFin; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public String getValidePar() { return validePar; }
    public void setValidePar(String validePar) { this.validePar = validePar; }
    public LocalDate getDateValidation() { return dateValidation; }
    public void setDateValidation(LocalDate dateValidation) { this.dateValidation = dateValidation; }
}
