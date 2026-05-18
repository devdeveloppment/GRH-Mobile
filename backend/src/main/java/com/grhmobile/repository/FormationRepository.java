package com.grhmobile.repository;

import com.grhmobile.entity.Formation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FormationRepository extends JpaRepository<Formation, Long> {

    List<Formation> findByStatutOrderByDateDebutDesc(String statut);

    List<Formation> findAllByOrderByDateDebutDesc();
}
