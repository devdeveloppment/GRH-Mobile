package com.grhmobile.repository;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.ClotureIntegration;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClotureIntegrationRepository extends JpaRepository<ClotureIntegration, Long> {
    Optional<ClotureIntegration> findByEmployeIdAndType(Long employeId, String type);
    List<ClotureIntegration> findByEmployeId(Long employeId);
}
