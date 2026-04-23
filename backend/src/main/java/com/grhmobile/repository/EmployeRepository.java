package com.grhmobile.repository;

import java.util.List;
import java.util.Optional;

import com.grhmobile.entity.Employe;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmployeRepository extends JpaRepository<Employe, Long> {

    Optional<Employe> findByMatricule(String matricule);

    Optional<Employe> findByUtilisateurId(Long utilisateurId);

    @Query("""
        select e from Employe e
        left join e.service s
        where (:query is null or lower(e.nom) like lower(concat('%', :query, '%'))
               or lower(e.prenom) like lower(concat('%', :query, '%'))
               or lower(e.matricule) like lower(concat('%', :query, '%'))
               or lower(e.poste) like lower(concat('%', :query, '%')))
          and (:statut is null or e.statut = :statut)
          and (:service is null or lower(s.nom) = lower(:service))
        """)
    Page<Employe> search(
        @Param("query") String query,
        @Param("statut") String statut,
        @Param("service") String service,
        Pageable pageable
    );

    List<Employe> findAllByStatutIgnoreCase(String statut);
}
