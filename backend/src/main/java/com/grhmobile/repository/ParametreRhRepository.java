package com.grhmobile.repository;

import java.util.Optional;

import com.grhmobile.entity.ParametreRh;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ParametreRhRepository extends JpaRepository<ParametreRh, Long> {
    Optional<ParametreRh> findByCle(String cle);
}
