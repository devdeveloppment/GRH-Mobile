package com.grhmobile.repository;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.FichePaie;

import org.springframework.data.jpa.repository.JpaRepository;

public interface FichePaieRepository extends JpaRepository<FichePaie, Long> {

    List<FichePaie> findByPeriodeOrderByEmployeNomAsc(String periode);

    List<FichePaie> findByEmployeIdOrderByPeriodeDesc(Long employeId);

    Optional<FichePaie> findByEmployeIdAndPeriode(Long employeId, String periode);

    long countByPeriode(String periode);
}
