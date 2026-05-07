package com.grhmobile.repository;

import java.time.LocalDate;
import java.util.List;

import com.grhmobile.entity.Conge;
import com.grhmobile.enums.StatutConge;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CongeRepository extends JpaRepository<Conge, Long> {

    List<Conge> findByEmployeIdOrderByDateDebutDesc(Long employeId);

    List<Conge> findByStatutOrderByDateDebutDesc(StatutConge statut);

    List<Conge> findByDateDebutBetweenOrderByDateDebutAsc(LocalDate debut, LocalDate fin);

    long countByStatut(StatutConge statut);
}
