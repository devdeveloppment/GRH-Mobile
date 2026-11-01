package com.grhmobile.repository;

import java.time.LocalDate;
import java.util.List;

import com.grhmobile.entity.JourFerie;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JourFerieRepository extends JpaRepository<JourFerie, Long> {
    List<JourFerie> findAllByOrderByDateAsc();
    List<JourFerie> findByDateBetween(LocalDate debut, LocalDate fin);
    boolean existsByDate(LocalDate date);
}
