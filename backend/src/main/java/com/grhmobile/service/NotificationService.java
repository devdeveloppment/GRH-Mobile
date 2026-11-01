package com.grhmobile.service;

import com.grhmobile.repository.AppSettingRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

import com.grhmobile.dto.notification.NotificationDto;
import com.grhmobile.entity.Notification;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.NotificationRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final AppSettingRepository appSettingRepository;

    public NotificationService(
            NotificationRepository notificationRepository,
            UtilisateurRepository utilisateurRepository,
            AppSettingRepository appSettingRepository) {
        this.appSettingRepository = appSettingRepository;
        this.notificationRepository = notificationRepository;
        this.utilisateurRepository = utilisateurRepository;
    }

    /** Crée une notification sans redirection. */
    @Transactional
    public void create(Long utilisateurId, String titre, String message, String type) {
        create(utilisateurId, titre, message, type, null);
    }

    /** Crée une notification avec redirection vers une route Flutter. */
    @Transactional
    public void create(Long utilisateurId, String titre, String message, String type, String redirectTo) {
        boolean enabled = appSettingRepository.findByKey("NOTIFICATIONS").map(s -> s.isEnabled()).orElse(true);
        if (!enabled) {
            return;
        }
        Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
            .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        Notification notification = new Notification();
        notification.setUtilisateur(utilisateur);
        notification.setTitre(titre);
        notification.setMessage(message);
        notification.setType(type);
        notification.setRedirectTo(redirectTo);
        notificationRepository.save(notification);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getForUser(Long utilisateurId) {
        List<NotificationDto> items = notificationRepository
            .findByUtilisateurIdOrderByCreatedAtDesc(utilisateurId)
            .stream()
            .map(NotificationDto::fromEntity)
            .toList();
        long unread = notificationRepository.countByUtilisateurIdAndLuFalse(utilisateurId);
        return Map.of("items", items, "total", items.size(), "unread", unread);
    }

    @Transactional
    public void markRead(Long notifId, Long utilisateurId) {
        Notification notification = notificationRepository.findById(notifId)
            .orElseThrow(() -> new ResourceNotFoundException("Notification introuvable."));
        if (!notification.getUtilisateur().getId().equals(utilisateurId)) {
            throw new ResourceNotFoundException("Notification introuvable.");
        }
        if (!notification.isLu()) {
            notification.setLu(true);
            notification.setReadAt(OffsetDateTime.now());
            notificationRepository.save(notification);
        }
    }

    @Transactional
    public void markAllRead(Long utilisateurId) {
        notificationRepository.markAllReadForUser(utilisateurId, OffsetDateTime.now());
    }

    /** Purge automatique : supprime les notifications lues depuis plus de 90 jours. */
    @Scheduled(cron = "0 0 3 * * *")
    public void purgeOldNotifications() {
        OffsetDateTime cutoff = OffsetDateTime.now().minusDays(90);
        // Une purge par entreprise : le contexte doit être fixé avant l'ouverture de la transaction.
        for (Long id : entrepriseRepository.findAllByOrderByIdAsc().stream().map(e -> e.getId()).toList()) {
            com.grhmobile.tenant.TenantContext.executer(id,
                () -> transactionTemplate.executeWithoutResult(st -> notificationRepository.deleteOldRead(cutoff)));
        }
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.grhmobile.repository.EntrepriseRepository entrepriseRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private org.springframework.transaction.support.TransactionTemplate transactionTemplate;
}
