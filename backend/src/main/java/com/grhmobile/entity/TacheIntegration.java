package com.grhmobile.entity;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.persistence.*;

/** Tâche d'une liste d'arrivée (ARRIVEE) ou de départ (DEPART) d'un employé. */
@Entity
@Table(name = "taches_integration")
public class TacheIntegration extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(nullable = false, length = 10)
    private String type;

    @Column(nullable = false)
    private String libelle;

    @Column(nullable = false)
    private int ordre;

    private LocalDate echeance;

    @Column(nullable = false)
    private boolean faite;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "faite_par")
    private Utilisateur faitePar;

    @Column(name = "faite_le")
    private OffsetDateTime faiteLe;

    public Long getId() { return id; }
    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
    public int getOrdre() { return ordre; }
    public void setOrdre(int ordre) { this.ordre = ordre; }
    public LocalDate getEcheance() { return echeance; }
    public void setEcheance(LocalDate echeance) { this.echeance = echeance; }
    public boolean isFaite() { return faite; }
    public void setFaite(boolean faite) { this.faite = faite; }
    public Utilisateur getFaitePar() { return faitePar; }
    public void setFaitePar(Utilisateur faitePar) { this.faitePar = faitePar; }
    public OffsetDateTime getFaiteLe() { return faiteLe; }
    public void setFaiteLe(OffsetDateTime faiteLe) { this.faiteLe = faiteLe; }
}
