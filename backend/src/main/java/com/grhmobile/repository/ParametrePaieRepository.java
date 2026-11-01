package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.ParametrePaie;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ParametrePaieRepository extends JpaRepository<ParametrePaie, Long> {
    List<ParametrePaie> findAllByOrderByCodeAscDateDebutDesc();
}
