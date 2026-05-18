package com.grhmobile.service;

import com.grhmobile.dto.audit.AuditLogResponse;
import com.grhmobile.dto.common.PagedResponse;
import com.grhmobile.entity.AuditLog;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.repository.AuditLogRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
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

    @Transactional
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

    @Transactional(readOnly = true)
    public PagedResponse<AuditLogResponse> search(String entite, String action,
                                                   Long acteurId, OffsetDateTime debut,
                                                   OffsetDateTime fin, int page, int limit) {
        Page<AuditLog> result = auditLogRepository.search(
            entite, action != null ? "%" + action + "%" : null,
            acteurId, debut, fin,
            PageRequest.of(Math.max(page - 1, 0), limit, Sort.by("createdAt").descending())
        );
        List<AuditLogResponse> items = result.getContent()
            .stream()
            .map(AuditLogResponse::fromEntity)
            .toList();
        return new PagedResponse<>(items, result.getTotalElements(), page, limit);
    }
}
