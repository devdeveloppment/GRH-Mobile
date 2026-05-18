package com.grhmobile.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "participations_formation",
    uniqueConstraints = @UniqueConstraint(columnNames = {"formation_id", "employe_id"}))
public class ParticipationFormation extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "formation_id", nullable = false)
    private Formation formation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    // INSCRIT, EN_COURS, TERMINE, ABANDONNE
    @Column(nullable = false, length = 30)
    private String statut = "INSCRIT";

    private Integer note;

    @Column(name = "certificat_url", length = 500)
    private String certificatUrl;

    public Long getId() { return id; }

    public Formation getFormation() { return formation; }
    public void setFormation(Formation formation) { this.formation = formation; }

    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public Integer getNote() { return note; }
    public void setNote(Integer note) { this.note = note; }

    public String getCertificatUrl() { return certificatUrl; }
    public void setCertificatUrl(String certificatUrl) { this.certificatUrl = certificatUrl; }
}
