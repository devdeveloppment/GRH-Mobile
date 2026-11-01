package com.grhmobile.repository;

import com.grhmobile.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    /**
     * Recherche paginée avec LEFT JOIN FETCH sur l'acteur pour éviter
     * la LazyInitializationException lors de la sérialisation.
     * Le filtre acteur utilise l'ID de l'utilisateur (nullable en base via ON
     * DELETE SET NULL).
     * La clause "(:acteur is null or ...)" gère les cas où le paramètre n'est pas
     * fourni.
     * Pour les entrées où acteur_id IS NULL (utilisateur supprimé), la ligne est
     * toujours retournée.
     */
    @Query("""
            select a from AuditLog a
            left join fetch a.acteur u
            where (:entite is null or a.entite = :entite)
              and (:action is null or a.action like :action)
              and (cast(:acteurEmail as string) is null
                   or (u is not null and lower(u.email) like lower(concat('%', cast(:acteurEmail as string), '%'))))
              and (cast(:debut as timestamp) is null or a.createdAt >= :debut)
              and (cast(:fin as timestamp) is null or a.createdAt <= :fin)
            """)
    Page<AuditLog> search(
            @Param("entite") String entite,
            @Param("action") String action,
            @Param("acteurEmail") String acteurEmail,
            @Param("debut") OffsetDateTime debut,
            @Param("fin") OffsetDateTime fin,
            Pageable pageable);
}
