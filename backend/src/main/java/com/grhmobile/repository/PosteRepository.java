package com.grhmobile.repository;

import com.grhmobile.entity.Poste;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PosteRepository extends JpaRepository<Poste, Long> {

    Optional<Poste> findByCodeIgnoreCase(String code);

    List<Poste> findByActifTrue();

    List<Poste> findByDepartementIdAndActifTrue(Long departementId);

    boolean existsByCodeIgnoreCase(String code);
}
