package com.grhmobile.repository;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.Entreprise;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EntrepriseRepository extends JpaRepository<Entreprise, Long> {
    Optional<Entreprise> findBySlug(String slug);
    List<Entreprise> findByStatutOrderByIdAsc(String statut);
    List<Entreprise> findAllByOrderByIdAsc();
}
