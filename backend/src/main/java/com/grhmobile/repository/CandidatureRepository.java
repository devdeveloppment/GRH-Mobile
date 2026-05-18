package com.grhmobile.repository;

import com.grhmobile.entity.Candidature;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CandidatureRepository extends JpaRepository<Candidature, Long> {

    List<Candidature> findByOffreIdOrderByCreatedAtDesc(Long offreId);
}
