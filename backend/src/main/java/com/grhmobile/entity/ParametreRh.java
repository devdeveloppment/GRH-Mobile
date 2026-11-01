package com.grhmobile.entity;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/** Paramètre RH de l'entreprise (clé / valeur). */
@Entity
@Table(name = "parametres_rh")
public class ParametreRh {

    @Id
    @Column(length = 80)
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

    public String getCle() { return cle; }
    public void setCle(String cle) { this.cle = cle; }
    public String getValeur() { return valeur; }
    public void setValeur(String valeur) { this.valeur = valeur; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
}
