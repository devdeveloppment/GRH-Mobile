package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.TacheIntegration;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TacheIntegrationRepository extends JpaRepository<TacheIntegration, Long> {
    List<TacheIntegration> findByEmployeIdOrderByTypeAscOrdreAsc(Long employeId);
    boolean existsByEmployeIdAndType(Long employeId, String type);
}
