package com.grhmobile.repository;

import com.grhmobile.entity.OffreEmploi;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OffreEmploiRepository extends JpaRepository<OffreEmploi, Long> {

    List<OffreEmploi> findByStatutOrderByCreatedAtDesc(String statut);

    List<OffreEmploi> findAllByOrderByCreatedAtDesc();
}
