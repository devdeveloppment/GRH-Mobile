package com.grhmobile.entity;

import java.time.LocalDate;

import jakarta.persistence.*;

/** Jour férié saisi par l'entreprise (aucune liste légale n'est fournie par défaut). */
@Entity
@Table(name = "jours_feries")
public class JourFerie extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private LocalDate date;

    @Column(nullable = false, length = 200)
    private String libelle;

    public Long getId() { return id; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }
}
