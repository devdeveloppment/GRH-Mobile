package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.NoteFrais;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteFraisRepository extends JpaRepository<NoteFrais, Long> {
    List<NoteFrais> findByEmployeIdOrderByCreatedAtDesc(Long employeId);
    List<NoteFrais> findAllByOrderByCreatedAtDesc();
    List<NoteFrais> findByStatutOrderByCreatedAtDesc(String statut);
}
