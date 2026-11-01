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

    /** Validé = une source officielle et un validateur (expert-comptable, juriste) sont renseignés. */
    public boolean estValide() {
        return validePar != null && !validePar.isBlank() && source != null && !source.isBlank();
    }

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
