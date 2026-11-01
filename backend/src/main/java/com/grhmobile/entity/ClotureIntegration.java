package com.grhmobile.entity;

import java.time.OffsetDateTime;

import jakarta.persistence.*;

/** Clôture d'un processus d'arrivée ou de départ, une fois toutes les tâches faites. */
@Entity
@Table(name = "clotures_integration")
public class ClotureIntegration extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employe_id", nullable = false)
    private Employe employe;

    @Column(nullable = false, length = 10)
    private String type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cloture_par")
    private Utilisateur cloturePar;

    @Column(name = "cloture_le", nullable = false)
    private OffsetDateTime clotureLe = OffsetDateTime.now();

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    public Long getId() { return id; }
    public Employe getEmploye() { return employe; }
    public void setEmploye(Employe employe) { this.employe = employe; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Utilisateur getCloturePar() { return cloturePar; }
    public void setCloturePar(Utilisateur cloturePar) { this.cloturePar = cloturePar; }
    public OffsetDateTime getClotureLe() { return clotureLe; }
    public String getCommentaire() { return commentaire; }
    public void setCommentaire(String commentaire) { this.commentaire = commentaire; }
}
