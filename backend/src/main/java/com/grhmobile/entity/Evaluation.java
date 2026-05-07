package com.grhmobile.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "evaluations")
public class Evaluation extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "evaluateur_id")
    private Utilisateur evaluateur;

    @Column(nullable = false, length = 20)
    private String periode;

    @Column(nullable = false)
    private int note;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    public Long getId() { return id; }

    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }

    public Utilisateur getEvaluateur() { return evaluateur; }
    public void setEvaluateur(Utilisateur evaluateur) { this.evaluateur = evaluateur; }

    public String getPeriode() { return periode; }
    public void setPeriode(String periode) { this.periode = periode; }

    public int getNote() { return note; }
    public void setNote(int note) { this.note = note; }

    public String getCommentaire() { return commentaire; }
    public void setCommentaire(String commentaire) { this.commentaire = commentaire; }
}
