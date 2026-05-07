package com.grhmobile.service;

import java.util.List;
import java.util.Map;

import com.grhmobile.dto.notification.NotificationDto;
import com.grhmobile.entity.Notification;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.NotificationRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UtilisateurRepository utilisateurRepository;

    public NotificationService(
            NotificationRepository notificationRepository,
            UtilisateurRepository utilisateurRepository) {
        this.notificationRepository = notificationRepository;
        this.utilisateurRepository = utilisateurRepository;
    }

    @Transactional
    public void create(Long utilisateurId, String titre, String message, String type) {
        Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
            .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        Notification notification = new Notification();
        notification.setUtilisateur(utilisateur);
        notification.setTitre(titre);
        notification.setMessage(message);
        notification.setType(type);
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
        notification.setLu(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllRead(Long utilisateurId) {
        notificationRepository.markAllReadForUser(utilisateurId);
    }
}
