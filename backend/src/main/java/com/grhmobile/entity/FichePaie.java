package com.grhmobile.entity;

import java.math.BigDecimal;
import java.time.YearMonth;

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
@Table(name = "fiches_paie")
public class FichePaie extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(nullable = false)
    private String periode;

    @Column(name = "salaire_brut", nullable = false, precision = 14, scale = 2)
    private BigDecimal salaireBrut = BigDecimal.ZERO;

    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal cotisations = BigDecimal.ZERO;

    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal impots = BigDecimal.ZERO;

    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal indemnites = BigDecimal.ZERO;

    @Column(name = "salaire_net", nullable = false, precision = 14, scale = 2)
    private BigDecimal salaireNet = BigDecimal.ZERO;

    @Column(nullable = false)
    private boolean calculee = false;

    @Column(nullable = false)
    private boolean validee = false;

    @Column(name = "autres_retenues", nullable = false, precision = 18, scale = 2)
    private BigDecimal autresRetenues = BigDecimal.ZERO;

    /** Vrai seulement si toutes les règles utilisées sont validées (voir PaieMoteurService). */
    @Column(name = "conforme_reglementation", nullable = false)
    private boolean conformeReglementation = false;

    @Column(name = "avertissement", columnDefinition = "TEXT")
    private String avertissement;

    public BigDecimal getAutresRetenues() { return autresRetenues; }
    public void setAutresRetenues(BigDecimal autresRetenues) { this.autresRetenues = autresRetenues; }
    public boolean isConformeReglementation() { return conformeReglementation; }
    public void setConformeReglementation(boolean conformeReglementation) { this.conformeReglementation = conformeReglementation; }
    public String getAvertissement() { return avertissement; }
    public void setAvertissement(String avertissement) { this.avertissement = avertissement; }

    public static String formatPeriode(YearMonth period) {
        return "%d-%02d".formatted(period.getYear(), period.getMonthValue());
    }

    public Long getId() {
        return id;
    }

    public Employe getEmploye() {
        return employe;
    }

    public void setEmploye(Employe employe) {
        this.employe = employe;
    }

    public String getPeriode() {
        return periode;
    }

    public void setPeriode(String periode) {
        this.periode = periode;
    }

    public BigDecimal getSalaireBrut() {
        return salaireBrut;
    }

    public void setSalaireBrut(BigDecimal salaireBrut) {
        this.salaireBrut = salaireBrut;
    }

    public BigDecimal getCotisations() {
        return cotisations;
    }

    public void setCotisations(BigDecimal cotisations) {
        this.cotisations = cotisations;
    }

    public BigDecimal getImpots() {
        return impots;
    }

    public void setImpots(BigDecimal impots) {
        this.impots = impots;
    }

    public BigDecimal getIndemnites() {
        return indemnites;
    }

    public void setIndemnites(BigDecimal indemnites) {
        this.indemnites = indemnites;
    }

    public BigDecimal getSalaireNet() {
        return salaireNet;
    }

    public void setSalaireNet(BigDecimal salaireNet) {
        this.salaireNet = salaireNet;
    }

    public boolean isCalculee() {
        return calculee;
    }

    public void setCalculee(boolean calculee) {
        this.calculee = calculee;
    }

    public boolean isValidee() {
        return validee;
    }

    public void setValidee(boolean validee) {
        this.validee = validee;
    }
}
