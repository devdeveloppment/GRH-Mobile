package com.grhmobile.repository;

import com.grhmobile.entity.ParticipationFormation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ParticipationFormationRepository extends JpaRepository<ParticipationFormation, Long> {

    List<ParticipationFormation> findByFormationId(Long formationId);

    List<ParticipationFormation> findByEmployeId(Long employeId);

    Optional<ParticipationFormation> findByFormationIdAndEmployeId(Long formationId, Long employeId);

    boolean existsByFormationIdAndEmployeId(Long formationId, Long employeId);
}
