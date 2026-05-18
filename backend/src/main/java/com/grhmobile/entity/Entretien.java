package com.grhmobile.entity;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "entretiens")
public class Entretien extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidature_id", nullable = false)
    private Candidature candidature;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "intervieweur_id")
    private Utilisateur intervieweur;

    @Column(name = "date_heure", nullable = false)
    private OffsetDateTime dateHeure;

    // TELEPHONE, VISIO, PRESENTIEL
    @Column(nullable = false, length = 30)
    private String type = "TELEPHONE";

    private Integer note;

    @Column(name = "compte_rendu", columnDefinition = "TEXT")
    private String compteRendu;

    // PLANIFIE, REALISE, ANNULE
    @Column(nullable = false, length = 20)
    private String statut = "PLANIFIE";

    public Long getId() { return id; }

    public Candidature getCandidature() { return candidature; }
    public void setCandidature(Candidature candidature) { this.candidature = candidature; }

    public Utilisateur getIntervieweur() { return intervieweur; }
    public void setIntervieweur(Utilisateur intervieweur) { this.intervieweur = intervieweur; }

    public OffsetDateTime getDateHeure() { return dateHeure; }
    public void setDateHeure(OffsetDateTime dateHeure) { this.dateHeure = dateHeure; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Integer getNote() { return note; }
    public void setNote(Integer note) { this.note = note; }

    public String getCompteRendu() { return compteRendu; }
    public void setCompteRendu(String compteRendu) { this.compteRendu = compteRendu; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
}
