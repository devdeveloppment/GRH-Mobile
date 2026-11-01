package com.grhmobile.service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import com.grhmobile.entity.Contrat;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.repository.ContratRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rappels automatiques. Chaque alerte n'est envoyée qu'une fois grâce à la table
 * alertes_automatiques (clé unique, insertion « ON CONFLICT DO NOTHING »).
 */
@Service
public class AlertesAutomatiquesService {

    private static final Logger log = LoggerFactory.getLogger(AlertesAutomatiquesService.class);
    static final int JOURS_AVANT_EXPIRATION = 30;

    private final ContratRepository contratRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final NotificationService notificationService;
    private final JdbcTemplate jdbcTemplate;

    public AlertesAutomatiquesService(ContratRepository contratRepository, UtilisateurRepository utilisateurRepository,
                                      NotificationService notificationService, JdbcTemplate jdbcTemplate) {
        this.contratRepository = contratRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.notificationService = notificationService;
        this.jdbcTemplate = jdbcTemplate;
    }

    /** Chaque jour à 07:00. */
    @Scheduled(cron = "0 0 7 * * *")
    public void executionQuotidienne() {
        log.info("Alertes contrats : {}", alerterContratsExpirant(LocalDate.now()));
    }

    @Transactional
    public Map<String, Object> alerterContratsExpirant(LocalDate aujourdHui) {
        List<Contrat> contrats = contratRepository.findExpiringBefore(aujourdHui, aujourdHui.plusDays(JOURS_AVANT_EXPIRATION));
        List<Utilisateur> destinataires = utilisateurRepository.findByRoleInAndActifTrue(
            List.of(Role.ADMIN, Role.SUPER_ADMIN, Role.HR_ADMIN, Role.RH_MANAGER));
        int envoyees = 0;
        for (Contrat c : contrats) {
            String cle = "CONTRAT_EXPIRE:" + c.getId() + ":" + c.getDateFin();
            int inserted = jdbcTemplate.update(
                "INSERT INTO alertes_automatiques (cle) VALUES (?) ON CONFLICT (cle) DO NOTHING", cle);
            if (inserted == 0) {
                continue;
            }
            String message = "Le contrat " + c.getTypeContrat() + " de " + c.getEmploye().getPrenom() + " "
                + c.getEmploye().getNom() + " expire le " + c.getDateFin() + ".";
            for (Utilisateur u : destinataires) {
                notificationService.create(u.getId(), "Contrat bientôt expiré", message, "CONTRAT", "/rh/contrats");
            }
            envoyees++;
        }
        return Map.of("contratsConcernes", contrats.size(), "nouvellesAlertes", envoyees);
    }
}
