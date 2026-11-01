package com.grhmobile.repository;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.RubriquePaie;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RubriquePaieRepository extends JpaRepository<RubriquePaie, Long> {
    List<RubriquePaie> findAllByOrderByOrdreAsc();
    List<RubriquePaie> findByActifTrueOrderByOrdreAsc();
    Optional<RubriquePaie> findByCode(String code);
}
