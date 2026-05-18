package com.grhmobile.repository;

import java.time.OffsetDateTime;
import java.util.List;

import com.grhmobile.entity.Notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUtilisateurIdOrderByCreatedAtDesc(Long utilisateurId);

    long countByUtilisateurIdAndLuFalse(Long utilisateurId);

    @Modifying
    @Query("UPDATE Notification n SET n.lu = true, n.readAt = :now WHERE n.utilisateur.id = :userId AND n.lu = false")
    void markAllReadForUser(@Param("userId") Long userId, @Param("now") OffsetDateTime now);

    @Modifying
    @Query("DELETE FROM Notification n WHERE n.lu = true AND n.readAt < :cutoff")
    int deleteOldRead(@Param("cutoff") OffsetDateTime cutoff);
}
