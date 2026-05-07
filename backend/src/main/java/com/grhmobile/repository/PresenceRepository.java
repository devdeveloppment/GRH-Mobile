package com.grhmobile.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.Presence;
import com.grhmobile.enums.StatutPresence;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PresenceRepository extends JpaRepository<Presence, Long> {

    List<Presence> findByEmployeIdOrderByDateDesc(Long employeId);

    List<Presence> findTop50ByOrderByDateDesc();

    long countByDateAndStatut(LocalDate date, StatutPresence statut);

    long countByDate(LocalDate date);

    boolean existsByEmployeIdAndDateAndStatut(Long employeId, LocalDate date, StatutPresence statut);

    List<Presence> findByDateBetweenOrderByDateAsc(LocalDate startDate, LocalDate endDate);

    Optional<Presence> findByEmployeIdAndDate(Long employeId, LocalDate date);

    List<Presence> findByEmployeIdAndStatutOrderByDateDesc(Long employeId, StatutPresence statut);

    List<Presence> findByStatutOrderByDateDesc(StatutPresence statut);
}
