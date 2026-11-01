package com.grhmobile.audit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.grhmobile.service.AuditLogService;
import com.grhmobile.security.AuthenticatedUserService;

import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Aspect
@Component
public class AuditAspect {

    private final AuditLogService auditLogService;
    private final AuthenticatedUserService authService;
    private final ObjectMapper objectMapper;

    public AuditAspect(AuditLogService auditLogService,
                       AuthenticatedUserService authService,
                       ObjectMapper objectMapper) {
        this.auditLogService = auditLogService;
        this.authService = authService;
        this.objectMapper = objectMapper;
    }

    @Around("@annotation(auditable)")
    public Object audit(ProceedingJoinPoint pjp, Auditable auditable) throws Throwable {
        Long acteurId = resolveActeurId();
        String ip = resolveIp();

        Object result = pjp.proceed();

        try {
            String apres = serialize(result != null ? result : sanitizedArgs(pjp.getArgs()));
            Long entiteId = extractId(result);
            auditLogService.log(acteurId, auditable.action(), auditable.entite(), entiteId, null, apres, ip);
        } catch (Exception ignored) {
            // Ne jamais bloquer le flux principal pour un log
        }

        return result;
    }

    private Long resolveActeurId() {
        try {
            return authService.currentUser().getId();
        } catch (Exception e) {
            return null;
        }
    }

    /** Sérialise en retirant les champs sensibles (mots de passe). */
    private String serialize(Object value) throws Exception {
        if (value == null) {
            return null;
        }
        com.fasterxml.jackson.databind.JsonNode node = objectMapper.valueToTree(value);
        stripSecrets(node);
        return objectMapper.writeValueAsString(node);
    }

    private void stripSecrets(com.fasterxml.jackson.databind.JsonNode node) {
        if (node instanceof com.fasterxml.jackson.databind.node.ObjectNode object) {
            object.remove(java.util.List.of("motDePasse", "motDePasseTemporaire", "password", "token"));
            object.forEach(this::stripSecrets);
        } else if (node != null && node.isArray()) {
            node.forEach(this::stripSecrets);
        }
    }

    private Object sanitizedArgs(Object[] args) {
        if (args == null || args.length == 0) {
            return null;
        }
        java.util.List<Object> kept = new java.util.ArrayList<>();
        for (Object arg : args) {
            if (arg instanceof org.springframework.web.multipart.MultipartFile file) {
                kept.add(java.util.Map.of("fichier", String.valueOf(file.getOriginalFilename())));
            } else {
                kept.add(arg);
            }
        }
        return kept;
    }

    private String resolveIp() {
        try {
            var attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return null;
            HttpServletRequest req = attrs.getRequest();
            String forwarded = req.getHeader("X-Forwarded-For");
            return forwarded != null ? forwarded.split(",")[0].trim() : req.getRemoteAddr();
        } catch (Exception e) {
            return null;
        }
    }

    private Long extractId(Object result) {
        if (result == null) return null;
        try {
            var method = result.getClass().getMethod("id");
            Object val = method.invoke(result);
            return val instanceof Long l ? l : null;
        } catch (Exception e) {
            return null;
        }
    }
}
