package com.grhmobile.entity;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.TypeConge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "conges")
public class Conge extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_conge", nullable = false)
    private TypeConge typeConge;

    @Column(name = "date_debut", nullable = false)
    private LocalDate dateDebut;

    @Column(name = "date_fin", nullable = false)
    private LocalDate dateFin;

    @Column(name = "nombre_jours", nullable = false)
    private Integer nombreJours;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutConge statut = StatutConge.EN_ATTENTE;

    @Column(columnDefinition = "TEXT")
    private String motif;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    // Workflow double validation
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approbateur_id")
    private Utilisateur approbateur;

    @Column(name = "date_approbation")
    private OffsetDateTime dateApprobation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "validateur_id")
    private Utilisateur validateur;

    @Column(name = "date_validation")
    private OffsetDateTime dateValidation;

    public Long getId() {
        return id;
    }

    public Employe getEmploye() {
        return employe;
    }

    public void setEmploye(Employe employe) {
        this.employe = employe;
    }

    public TypeConge getTypeConge() {
        return typeConge;
    }

    public void setTypeConge(TypeConge typeConge) {
        this.typeConge = typeConge;
    }

    public LocalDate getDateDebut() {
        return dateDebut;
    }

    public void setDateDebut(LocalDate dateDebut) {
        this.dateDebut = dateDebut;
    }

    public LocalDate getDateFin() {
        return dateFin;
    }

    public void setDateFin(LocalDate dateFin) {
        this.dateFin = dateFin;
    }

    public Integer getNombreJours() {
        return nombreJours;
    }

    public void setNombreJours(Integer nombreJours) {
        this.nombreJours = nombreJours;
    }

    public StatutConge getStatut() {
        return statut;
    }

    public void setStatut(StatutConge statut) {
        this.statut = statut;
    }

    public String getMotif() {
        return motif;
    }

    public void setMotif(String motif) {
        this.motif = motif;
    }

    public String getCommentaire() {
        return commentaire;
    }

    public void setCommentaire(String commentaire) {
        this.commentaire = commentaire;
    }

    public Utilisateur getApprobateur() { return approbateur; }
    public void setApprobateur(Utilisateur approbateur) { this.approbateur = approbateur; }

    public OffsetDateTime getDateApprobation() { return dateApprobation; }
    public void setDateApprobation(OffsetDateTime dateApprobation) { this.dateApprobation = dateApprobation; }

    public Utilisateur getValidateur() { return validateur; }
    public void setValidateur(Utilisateur validateur) { this.validateur = validateur; }

    public OffsetDateTime getDateValidation() { return dateValidation; }
    public void setDateValidation(OffsetDateTime dateValidation) { this.dateValidation = dateValidation; }
}
