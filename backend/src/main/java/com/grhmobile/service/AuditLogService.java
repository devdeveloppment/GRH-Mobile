package com.grhmobile.service;

import com.grhmobile.dto.audit.AuditLogResponse;
import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.entity.AuditLog;
import com.grhmobile.repository.AuditLogRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final UtilisateurRepository utilisateurRepository;

    public AuditLogService(AuditLogRepository auditLogRepository,
            UtilisateurRepository utilisateurRepository) {
        this.auditLogRepository = auditLogRepository;
        this.utilisateurRepository = utilisateurRepository;
    }

    /**
     * Transaction indépendante : un échec d'écriture du journal ne doit jamais
     * marquer la transaction métier « rollback-only » (cause d'erreurs 500).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void log(Long acteurId, String action, String entite, Long entiteId,
            String avant, String apres, String ip) {
        AuditLog log = new AuditLog();
        if (acteurId != null) {
            utilisateurRepository.findById(acteurId).ifPresent(log::setActeur);
        }
        log.setAction(action);
        log.setEntite(entite);
        log.setEntiteId(entiteId);
        log.setAvant(avant);
        log.setApres(apres);
        log.setIpAddress(ip);
        auditLogRepository.save(log);
    }

    /**
     * Recherche paginée des entrées d'audit.
     *
     * @param entite      filtre optionnel sur le type d'entité
     * @param action      filtre optionnel sur l'action (LIKE %action%)
     * @param acteurEmail filtre optionnel sur l'email de l'acteur (correspondance
     *                    partielle)
     * @param debut       date de début (incluse)
     * @param fin         date de fin (incluse)
     * @param page        numéro de page (1-indexé côté client)
     * @param limit       taille de page
     */
    @Transactional(readOnly = true)
    public PagedResponse<AuditLogResponse> search(String entite, String action,
            String acteurEmail, OffsetDateTime debut,
            OffsetDateTime fin, int page, int limit) {
        // Normalise l'action pour une recherche LIKE
        String actionPattern = (action != null && !action.isBlank()) ? "%" + action + "%" : null;
        // Normalise l'email vide en null
        String emailFilter = (acteurEmail != null && !acteurEmail.isBlank()) ? acteurEmail : null;

        Page<AuditLog> result = auditLogRepository.search(
                (entite != null && !entite.isBlank()) ? entite : null,
                actionPattern,
                emailFilter,
                debut,
                fin,
                PageRequest.of(Math.max(page - 1, 0), limit, Sort.by("createdAt").descending()));

        List<AuditLogResponse> items = result.getContent()
                .stream()
                .map(AuditLogResponse::fromEntity)
                .toList();

        return new PagedResponse<>(items, result.getTotalElements(), page, limit);
    }
}
