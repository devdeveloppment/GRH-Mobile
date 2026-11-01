package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.TacheIntegration;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TacheIntegrationRepository extends JpaRepository<TacheIntegration, Long> {
    List<TacheIntegration> findByEmployeIdOrderByTypeAscOrdreAsc(Long employeId);
    boolean existsByEmployeIdAndType(Long employeId, String type);
    List<TacheIntegration> findByEmployeIdAndType(Long employeId, String type);

    @org.springframework.data.jpa.repository.Query(
        "select t from TacheIntegration t join fetch t.employe order by t.employe.nom, t.type, t.ordre")
    List<TacheIntegration> toutesAvecEmploye();
}
