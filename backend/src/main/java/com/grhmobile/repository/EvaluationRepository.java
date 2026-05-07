package com.grhmobile.repository;

import com.grhmobile.entity.Evaluation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EvaluationRepository extends JpaRepository<Evaluation, Long> {
    List<Evaluation> findByEmployeIdOrderByPeriodeDesc(Long employeId);
}
