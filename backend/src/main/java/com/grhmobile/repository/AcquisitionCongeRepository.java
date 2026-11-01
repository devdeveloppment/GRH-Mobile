package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.AcquisitionConge;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AcquisitionCongeRepository extends JpaRepository<AcquisitionConge, Long> {
    boolean existsByEmployeIdAndPeriode(Long employeId, String periode);
    List<AcquisitionConge> findByEmployeIdOrderByPeriodeDesc(Long employeId);
}
