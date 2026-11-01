package com.grhmobile.entity;

import java.util.Set;

import jakarta.persistence.*;

/** Ligne de calcul du bulletin : type, ordre d'évaluation et formule. */
@Entity
@Table(name = "rubriques_paie")
public class RubriquePaie extends BaseEntity {

    public static final Set<String> TYPES = Set.of("GAIN", "COTISATION_SALARIALE", "IMPOT", "RETENUE");

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 60)
    private String code;

    @Column(nullable = false, length = 200)
    private String libelle;

    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false)
    private int ordre;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String formule;

    @Column(nullable = false)
    private boolean actif = true;

    public Long getId() { return id; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public int getOrdre() { return ordre; }
    public void setOrdre(int ordre) { this.ordre = ordre; }
    public String getFormule() { return formule; }
    public void setFormule(String formule) { this.formule = formule; }
    public boolean isActif() { return actif; }
    public void setActif(boolean actif) { this.actif = actif; }
}
