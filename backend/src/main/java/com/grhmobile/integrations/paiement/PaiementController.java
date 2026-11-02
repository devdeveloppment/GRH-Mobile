package com.grhmobile.integrations.paiement;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

/** Paiements des abonnements (SUPER_ADMIN) et réception des notifications des fournisseurs. */
@RestController
public class PaiementController {

    private final PaiementService service;

    public PaiementController(PaiementService service) {
        this.service = service;
    }

    @GetMapping("/api/plateforme/paiements/statut")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public Map<String, Object> statut() {
        return service.statut();
    }

    @GetMapping("/api/plateforme/paiements")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public List<Map<String, Object>> transactions() {
        return service.transactions();
    }

    @PostMapping("/api/plateforme/paiements")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public Map<String, Object> initier(@RequestBody Map<String, Object> body,
                                       @RequestHeader(value = "Idempotency-Key", required = false) String cle) {
        return service.initier(Long.parseLong(String.valueOf(body.get("entrepriseId"))),
            new BigDecimal(String.valueOf(body.get("montant"))), (String) body.get("description"), cle);
    }

    /** Notification serveur à serveur (publique : l'authenticité repose sur la signature). */
    @PostMapping("/api/paiements/notifications/{fournisseur}")
    public ResponseEntity<Void> notification(@PathVariable String fournisseur, @RequestBody String corps,
                                             HttpServletRequest request) {
        Map<String, String> entetes = new HashMap<>();
        for (String n : Collections.list(request.getHeaderNames())) {
            entetes.put(n.toLowerCase(), request.getHeader(n));
        }
        return service.notification(fournisseur, corps, entetes)
            ? ResponseEntity.ok().build() : ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }

    @ExceptionHandler(PaiementService.PaiementIndisponibleException.class)
    public ResponseEntity<Map<String, Object>> indisponible(PaiementService.PaiementIndisponibleException e) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("status", 503, "message", e.getMessage()));
    }
}
