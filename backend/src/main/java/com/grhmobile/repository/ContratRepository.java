package com.grhmobile.repository;

import com.grhmobile.entity.Contrat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ContratRepository extends JpaRepository<Contrat, Long> {

    List<Contrat> findByEmployeIdOrderByDateDebutDesc(Long employeId);

    Optional<Contrat> findFirstByEmployeIdAndStatutOrderByDateDebutDesc(Long employeId, String statut);

    @Query("""
        select c from Contrat c
        where c.statut = 'ACTIF'
          and c.dateFin is not null
          and c.dateFin between :today and :limite
        """)
    List<Contrat> findExpiringBefore(@Param("today") LocalDate today, @Param("limite") LocalDate limite);
}
