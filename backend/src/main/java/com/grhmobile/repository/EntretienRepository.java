package com.grhmobile.repository;

import com.grhmobile.entity.Entretien;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EntretienRepository extends JpaRepository<Entretien, Long> {

    List<Entretien> findByCandidatureIdOrderByDateHeureAsc(Long candidatureId);
}
