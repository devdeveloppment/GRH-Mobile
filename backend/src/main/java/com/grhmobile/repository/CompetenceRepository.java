package com.grhmobile.repository;

import com.grhmobile.entity.Competence;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CompetenceRepository extends JpaRepository<Competence, Long> {
    List<Competence> findByEmployeIdOrderByNiveauDesc(Long employeId);
}
