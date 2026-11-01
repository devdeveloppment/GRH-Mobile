package com.grhmobile.entity;

import java.math.BigDecimal;

import jakarta.persistence.*;

/** Ligne calculée d'un bulletin, avec la formule et les paramètres utilisés (traçabilité). */
@Entity
@Table(name = "lignes_bulletin")
public class LigneBulletin extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fiche_paie_id", nullable = false)
    private FichePaie fichePaie;

    @Column(name = "rubrique_code", nullable = false, length = 60)
    private String rubriqueCode;

    @Column(nullable = false, length = 200)
    private String libelle;

    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false)
    private int ordre;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal montant;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String formule;

    @Column(name = "parametres_utilises", columnDefinition = "TEXT")
    private String parametresUtilises;

    public Long getId() { return id; }
    public FichePaie getFichePaie() { return fichePaie; }
    public void setFichePaie(FichePaie fichePaie) { this.fichePaie = fichePaie; }
    public String getRubriqueCode() { return rubriqueCode; }
    public void setRubriqueCode(String rubriqueCode) { this.rubriqueCode = rubriqueCode; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public int getOrdre() { return ordre; }
    public void setOrdre(int ordre) { this.ordre = ordre; }
    public BigDecimal getMontant() { return montant; }
    public void setMontant(BigDecimal montant) { this.montant = montant; }
    public String getFormule() { return formule; }
    public void setFormule(String formule) { this.formule = formule; }
    public String getParametresUtilises() { return parametresUtilises; }
    public void setParametresUtilises(String parametresUtilises) { this.parametresUtilises = parametresUtilises; }
}
