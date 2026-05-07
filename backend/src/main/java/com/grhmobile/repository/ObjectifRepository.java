package com.grhmobile.repository;

import com.grhmobile.entity.Objectif;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ObjectifRepository extends JpaRepository<Objectif, Long> {
    List<Objectif> findByEmployeIdOrderByCreatedAtDesc(Long employeId);
}
