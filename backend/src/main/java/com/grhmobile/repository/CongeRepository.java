package com.grhmobile.repository;

import java.time.LocalDate;
import java.util.List;

import com.grhmobile.entity.Conge;
import com.grhmobile.enums.StatutConge;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CongeRepository extends JpaRepository<Conge, Long> {

    List<Conge> findByEmployeIdOrderByDateDebutDesc(Long employeId);

    List<Conge> findAllByOrderByDateDebutDesc();

    /** Demandes en cours (en attente ou approuvées) chevauchant la période donnée. */
    @org.springframework.data.jpa.repository.Query("""
        SELECT c FROM Conge c
        WHERE c.employe.id = :employeId
          AND c.statut IN :statuts
          AND c.dateDebut <= :fin
          AND c.dateFin >= :debut
        """)
    List<Conge> findOverlapping(
        @org.springframework.data.repository.query.Param("employeId") Long employeId,
        @org.springframework.data.repository.query.Param("debut") LocalDate debut,
        @org.springframework.data.repository.query.Param("fin") LocalDate fin,
        @org.springframework.data.repository.query.Param("statuts") java.util.Collection<StatutConge> statuts);

    List<Conge> findByStatutOrderByDateDebutDesc(StatutConge statut);

    List<Conge> findByDateDebutBetweenOrderByDateDebutAsc(LocalDate debut, LocalDate fin);

    long countByStatut(StatutConge statut);
}
