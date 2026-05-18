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

    // ANNUELLE, SEMESTRIELLE, PROBATOIRE, 360
    @Column(nullable = false, length = 30)
    private String type = "ANNUELLE";

    // BROUILLON, SOUMISE, VALIDEE
    @Column(nullable = false, length = 20)
    private String statut = "BROUILLON";

    @Column(name = "note_competences", precision = 4, scale = 2)
    private java.math.BigDecimal noteCompetences;

    @Column(name = "note_objectifs", precision = 4, scale = 2)
    private java.math.BigDecimal noteObjectifs;

    @Column(name = "note_comportement", precision = 4, scale = 2)
    private java.math.BigDecimal noteComportement;

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

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public java.math.BigDecimal getNoteCompetences() { return noteCompetences; }
    public void setNoteCompetences(java.math.BigDecimal noteCompetences) { this.noteCompetences = noteCompetences; }

    public java.math.BigDecimal getNoteObjectifs() { return noteObjectifs; }
    public void setNoteObjectifs(java.math.BigDecimal noteObjectifs) { this.noteObjectifs = noteObjectifs; }

    public java.math.BigDecimal getNoteComportement() { return noteComportement; }
    public void setNoteComportement(java.math.BigDecimal noteComportement) { this.noteComportement = noteComportement; }
}
