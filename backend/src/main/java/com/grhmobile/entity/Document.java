package com.grhmobile.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "documents")
public class Document extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(nullable = false)
    private String nom;

    @Column(nullable = false)
    private String type;

    @Column(name = "taille_ko", nullable = false)
    private int tailleKo;

    private String url;

    public Long getId() { return id; }

    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public int getTailleKo() { return tailleKo; }
    public void setTailleKo(int tailleKo) { this.tailleKo = tailleKo; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
}
