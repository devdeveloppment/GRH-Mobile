package com.grhmobile.repository;

import java.util.List;

import com.grhmobile.entity.LigneBulletin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LigneBulletinRepository extends JpaRepository<LigneBulletin, Long> {
    List<LigneBulletin> findByFichePaieIdOrderByOrdreAsc(Long fichePaieId);

    @Modifying
    @Query("delete from LigneBulletin l where l.fichePaie.id = :ficheId")
    void deleteByFichePaieId(@Param("ficheId") Long ficheId);
}
