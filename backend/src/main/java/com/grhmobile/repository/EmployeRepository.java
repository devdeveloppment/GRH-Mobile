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

    @Query(value = """
        SELECT e.* FROM employes e
        LEFT JOIN services s ON e.service_id = s.id
        WHERE (cast(:pattern as text) IS NULL
               OR lower(e.nom::text)       LIKE cast(:pattern as text)
               OR lower(e.prenom::text)    LIKE cast(:pattern as text)
               OR lower(e.matricule::text) LIKE cast(:pattern as text)
               OR lower(e.email::text)     LIKE cast(:pattern as text)
               OR lower(e.poste::text)     LIKE cast(:pattern as text)
               OR lower(s.nom::text)       LIKE cast(:pattern as text))
          AND (cast(:statut as text) IS NULL OR e.statut = cast(:statut as text))
          AND (cast(:service as text) IS NULL OR lower(s.nom::text) = lower(cast(:service as text)))
        """,
        countQuery = """
        SELECT COUNT(e.id) FROM employes e
        LEFT JOIN services s ON e.service_id = s.id
        WHERE (cast(:pattern as text) IS NULL
               OR lower(e.nom::text)       LIKE cast(:pattern as text)
               OR lower(e.prenom::text)    LIKE cast(:pattern as text)
               OR lower(e.matricule::text) LIKE cast(:pattern as text)
               OR lower(e.email::text)     LIKE cast(:pattern as text)
               OR lower(e.poste::text)     LIKE cast(:pattern as text)
               OR lower(s.nom::text)       LIKE cast(:pattern as text))
          AND (cast(:statut as text) IS NULL OR e.statut = cast(:statut as text))
          AND (cast(:service as text) IS NULL OR lower(s.nom::text) = lower(cast(:service as text)))
        """,
        nativeQuery = true)
    Page<Employe> search(
        @Param("pattern") String pattern,
        @Param("statut") String statut,
        @Param("service") String service,
        Pageable pageable
    );

    List<Employe> findAllByStatutIgnoreCase(String statut);

    /** Équipe d'un manager : subordonnés directs et membres des départements qu'il dirige. */
    @Query("""
        SELECT e FROM Employe e
        LEFT JOIN e.departement d
        WHERE e.id <> :managerId
          AND (e.manager.id = :managerId OR d.manager.id = :managerId)
        ORDER BY e.nom ASC, e.prenom ASC
        """)
    List<Employe> findTeam(@Param("managerId") Long managerId);

    @Query(value = "SELECT nextval('employe_matricule_seq')", nativeQuery = true)
    Long nextMatriculeSequence();
}
