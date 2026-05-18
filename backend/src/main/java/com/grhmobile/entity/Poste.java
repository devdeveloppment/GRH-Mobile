package com.grhmobile.entity;

import java.math.BigDecimal;

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
@Table(name = "postes")
public class Poste extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(nullable = false)
    private String intitule;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "departement_id")
    private Departement departement;

    @Column(length = 50)
    private String niveau;

    @Column(name = "salaire_min", precision = 14, scale = 2)
    private BigDecimal salaireMin;

    @Column(name = "salaire_max", precision = 14, scale = 2)
    private BigDecimal salaireMax;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private boolean actif = true;

    public Long getId() { return id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getIntitule() { return intitule; }
    public void setIntitule(String intitule) { this.intitule = intitule; }

    public Departement getDepartement() { return departement; }
    public void setDepartement(Departement departement) { this.departement = departement; }

    public String getNiveau() { return niveau; }
    public void setNiveau(String niveau) { this.niveau = niveau; }

    public BigDecimal getSalaireMin() { return salaireMin; }
    public void setSalaireMin(BigDecimal salaireMin) { this.salaireMin = salaireMin; }

    public BigDecimal getSalaireMax() { return salaireMax; }
    public void setSalaireMax(BigDecimal salaireMax) { this.salaireMax = salaireMax; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public boolean isActif() { return actif; }
    public void setActif(boolean actif) { this.actif = actif; }
}
