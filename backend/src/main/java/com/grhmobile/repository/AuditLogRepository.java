package com.grhmobile.repository;

import com.grhmobile.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    @Query("""
        select a from AuditLog a
        where (:entite  is null or a.entite   = :entite)
          and (:action  is null or a.action   like :action)
          and (:acteur  is null or a.acteur.id = :acteur)
          and (:debut   is null or a.createdAt >= :debut)
          and (:fin     is null or a.createdAt <= :fin)
        order by a.createdAt desc
        """)
    Page<AuditLog> search(
        @Param("entite")  String entite,
        @Param("action")  String action,
        @Param("acteur")  Long   acteur,
        @Param("debut")   OffsetDateTime debut,
        @Param("fin")     OffsetDateTime fin,
        Pageable pageable
    );
}
