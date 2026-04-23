package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.Conge;
import com.grhmobile.enums.StatutConge;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CongeRepository extends JpaRepository<Conge, Long> {

    List<Conge> findByEmployeIdOrderByDateDebutDesc(Long employeId);

    List<Conge> findByStatutOrderByDateDebutDesc(StatutConge statut);

    long countByStatut(StatutConge statut);
}
