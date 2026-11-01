package com.grhmobile.entity;

import java.time.OffsetDateTime;

import com.grhmobile.enums.Role;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "utilisateurs")
public class Utilisateur extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String prenom;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "mot_de_passe", nullable = false)
    private String motDePasse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean actif = true;

    @Column(name = "date_creation", nullable = false)
    private OffsetDateTime dateCreation = OffsetDateTime.now();

    @OneToOne(mappedBy = "utilisateur")
    private Employe employe;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;

    @Column(name = "doit_changer_mot_de_passe", nullable = false)
    private boolean doitChangerMotDePasse = false;

    public boolean isDoitChangerMotDePasse() {
        return doitChangerMotDePasse;
    }

    public void setDoitChangerMotDePasse(boolean doitChangerMotDePasse) {
        this.doitChangerMotDePasse = doitChangerMotDePasse;
    }

    public Long getId() {
        return id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getPrenom() {
        return prenom;
    }

    public void setPrenom(String prenom) {
        this.prenom = prenom;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getMotDePasse() {
        return motDePasse;
    }

    public void setMotDePasse(String motDePasse) {
        this.motDePasse = motDePasse;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public boolean isActif() {
        return actif;
    }

    public void setActif(boolean actif) {
        this.actif = actif;
    }

    public OffsetDateTime getDateCreation() {
        return dateCreation;
    }

    public void setDateCreation(OffsetDateTime dateCreation) {
        this.dateCreation = dateCreation;
    }

    public Employe getEmploye() {
        return employe;
    }

    public void setEmploye(Employe employe) {
        this.employe = employe;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }
}
