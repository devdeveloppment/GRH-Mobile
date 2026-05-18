package com.grhmobile.repository;

import com.grhmobile.entity.Departement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface DepartementRepository extends JpaRepository<Departement, Long> {

    Optional<Departement> findByCodeIgnoreCase(String code);

    List<Departement> findByParentIsNullAndActifTrue();

    List<Departement> findByParentIdAndActifTrue(Long parentId);

    List<Departement> findByActifTrue();

    boolean existsByCodeIgnoreCase(String code);

    @Query("select d from Departement d left join fetch d.sousDepartements where d.parent is null and d.actif = true")
    List<Departement> findRootsWithChildren();
}
