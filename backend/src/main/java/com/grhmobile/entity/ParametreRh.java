package com.grhmobile.entity;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import org.hibernate.annotations.TenantId;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/** Paramètre RH de l'entreprise (clé / valeur). */
@Entity
@Table(name = "parametres_rh")
public class ParametreRh {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Entreprise propriétaire (multi-entreprise). */
    @TenantId
    @Column(name = "entreprise_id", nullable = false, updatable = false)
    private Long entrepriseId;

    @Column(nullable = false, length = 80)
    private String cle;

    @Column(length = 200)
    private String valeur;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    @PreUpdate
    void touch() {
        updatedAt = OffsetDateTime.now();
    }

    public Long getId() { return id; }
    public String getCle() { return cle; }
    public void setCle(String cle) { this.cle = cle; }
    public String getValeur() { return valeur; }
    public void setValeur(String valeur) { this.valeur = valeur; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
}
