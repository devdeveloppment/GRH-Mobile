package com.grhmobile.entity;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import jakarta.persistence.*;

/** Entreprise cliente (tenant). Table de plateforme : non soumise au filtre multi-entreprise. */
@Entity
@Table(name = "entreprises")
public class Entreprise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String nom;

    @Column(nullable = false, unique = true, length = 60)
    private String slug;

    @Column(nullable = false, length = 20)
    private String statut = "ACTIVE";

    @Column(nullable = false, length = 30)
    private String offre = "ESSAI";

    @Column(name = "date_fin_essai")
    private LocalDate dateFinEssai;

    @Column(nullable = false, length = 2)
    private String pays = "TG";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = OffsetDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public boolean estActive() {
        return "ACTIVE".equals(statut);
    }

    public Long getId() { return id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    public String getOffre() { return offre; }
    public void setOffre(String offre) { this.offre = offre; }
    public LocalDate getDateFinEssai() { return dateFinEssai; }
    public void setDateFinEssai(LocalDate dateFinEssai) { this.dateFinEssai = dateFinEssai; }
    public String getPays() { return pays; }
    public void setPays(String pays) { this.pays = pays; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
}
