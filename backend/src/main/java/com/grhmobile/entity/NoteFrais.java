package com.grhmobile.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Set;

import jakarta.persistence.*;

/** Note de frais d'un employé. « REMBOURSEE » est une déclaration manuelle : aucun paiement n'est effectué. */
@Entity
@Table(name = "notes_frais")
public class NoteFrais extends BaseEntity {

    public static final Set<String> CATEGORIES =
        Set.of("TRANSPORT", "REPAS", "HEBERGEMENT", "FOURNITURES", "COMMUNICATION", "AUTRE");

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(name = "date_depense", nullable = false)
    private LocalDate dateDepense;

    @Column(nullable = false, length = 30)
    private String categorie;

    @Column(nullable = false, precision = 14, scale = 2)
    private BigDecimal montant;

    @Column(nullable = false, length = 3)
    private String devise = "XOF";

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "justificatif_path")
    private String justificatifPath;

    @Column(name = "justificatif_nom")
    private String justificatifNom;

    @Column(nullable = false, length = 20)
    private String statut = "SOUMISE";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "decideur_id")
    private Utilisateur decideur;

    @Column(name = "date_decision")
    private OffsetDateTime dateDecision;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @Column(name = "reference_remboursement", length = 100)
    private String referenceRemboursement;

    @Column(name = "date_remboursement")
    private OffsetDateTime dateRemboursement;

    public Long getId() { return id; }
    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }
    public LocalDate getDateDepense() { return dateDepense; }
    public void setDateDepense(LocalDate dateDepense) { this.dateDepense = dateDepense; }
    public String getCategorie() { return categorie; }
    public void setCategorie(String categorie) { this.categorie = categorie; }
    public BigDecimal getMontant() { return montant; }
    public void setMontant(BigDecimal montant) { this.montant = montant; }
    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getJustificatifPath() { return justificatifPath; }
    public void setJustificatifPath(String justificatifPath) { this.justificatifPath = justificatifPath; }
    public String getJustificatifNom() { return justificatifNom; }
    public void setJustificatifNom(String justificatifNom) { this.justificatifNom = justificatifNom; }
    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    public Utilisateur getDecideur() { return decideur; }
    public void setDecideur(Utilisateur decideur) { this.decideur = decideur; }
    public OffsetDateTime getDateDecision() { return dateDecision; }
    public void setDateDecision(OffsetDateTime dateDecision) { this.dateDecision = dateDecision; }
    public String getCommentaire() { return commentaire; }
    public void setCommentaire(String commentaire) { this.commentaire = commentaire; }
    public String getReferenceRemboursement() { return referenceRemboursement; }
    public void setReferenceRemboursement(String referenceRemboursement) { this.referenceRemboursement = referenceRemboursement; }
    public OffsetDateTime getDateRemboursement() { return dateRemboursement; }
    public void setDateRemboursement(OffsetDateTime dateRemboursement) { this.dateRemboursement = dateRemboursement; }
}
