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
            String apres = result != null ? objectMapper.writeValueAsString(result) : null;
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
