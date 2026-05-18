package com.grhmobile.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "candidatures")
public class Candidature extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "offre_id", nullable = false)
    private OffreEmploi offre;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String prenom;

    @Column(nullable = false)
    private String email;

    private String telephone;

    @Column(name = "cv_url", length = 500)
    private String cvUrl;

    @Column(name = "cv_path", length = 500)
    private String cvPath;

    @Column(name = "cv_nom_fichier", length = 255)
    private String cvNomFichier;

    @Column(name = "lettre_motivation", columnDefinition = "TEXT")
    private String lettreMotivation;

    // RECUE, PRESELECTIONNE, ENTRETIEN, RETENU, REFUSE
    @Column(nullable = false, length = 30)
    private String statut = "RECUE";

    private Integer note;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @OneToMany(mappedBy = "candidature")
    private List<Entretien> entretiens = new ArrayList<>();

    public Long getId() { return id; }

    public OffreEmploi getOffre() { return offre; }
    public void setOffre(OffreEmploi offre) { this.offre = offre; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getTelephone() { return telephone; }
    public void setTelephone(String telephone) { this.telephone = telephone; }

    public String getCvUrl() { return cvUrl; }
    public void setCvUrl(String cvUrl) { this.cvUrl = cvUrl; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public Integer getNote() { return note; }
    public void setNote(Integer note) { this.note = note; }

    public String getCommentaire() { return commentaire; }
    public void setCommentaire(String commentaire) { this.commentaire = commentaire; }

    public String getCvPath() { return cvPath; }
    public void setCvPath(String cvPath) { this.cvPath = cvPath; }

    public String getCvNomFichier() { return cvNomFichier; }
    public void setCvNomFichier(String cvNomFichier) { this.cvNomFichier = cvNomFichier; }

    public String getLettreMotivation() { return lettreMotivation; }
    public void setLettreMotivation(String lettreMotivation) { this.lettreMotivation = lettreMotivation; }

    public List<Entretien> getEntretiens() { return entretiens; }
}
