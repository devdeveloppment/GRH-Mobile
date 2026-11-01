package com.grhmobile.entity;

import java.math.BigDecimal;

import jakarta.persistence.*;

/** Trace d'une acquisition mensuelle de congés (une seule par employé et par mois). */
@Entity
@Table(name = "acquisitions_conges")
public class AcquisitionConge extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(nullable = false, length = 7)
    private String periode;

    @Column(nullable = false, precision = 6, scale = 2)
    private BigDecimal jours;

    public Long getId() { return id; }
    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }
    public String getPeriode() { return periode; }
    public void setPeriode(String periode) { this.periode = periode; }
    public BigDecimal getJours() { return jours; }
    public void setJours(BigDecimal jours) { this.jours = jours; }
}
