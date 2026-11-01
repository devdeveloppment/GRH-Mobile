package com.grhmobile.entity;

import org.hibernate.annotations.TenantId;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
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
@Table(name = "audit_logs")
public class AuditLog {

    /** Entreprise propriétaire (multi-entreprise) : renseignée et filtrée automatiquement par Hibernate. */
    @TenantId
    @Column(name = "entreprise_id", nullable = false, updatable = false)
    private Long entrepriseId;

    public Long getEntrepriseId() {
        return entrepriseId;
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "acteur_id")
    private Utilisateur acteur;

    @Column(nullable = false, length = 100)
    private String action;

    @Column(nullable = false, length = 100)
    private String entite;

    @Column(name = "entite_id")
    private Long entiteId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "JSONB")
    private String avant;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "JSONB")
    private String apres;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public Long getId() { return id; }

    public Utilisateur getActeur() { return acteur; }
    public void setActeur(Utilisateur acteur) { this.acteur = acteur; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getEntite() { return entite; }
    public void setEntite(String entite) { this.entite = entite; }

    public Long getEntiteId() { return entiteId; }
    public void setEntiteId(Long entiteId) { this.entiteId = entiteId; }

    public String getAvant() { return avant; }
    public void setAvant(String avant) { this.avant = avant; }

    public String getApres() { return apres; }
    public void setApres(String apres) { this.apres = apres; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
}
