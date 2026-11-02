package com.grhmobile.security;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

/**
 * Rejeu sans doublon des opérations autorisées hors ligne. Si une requête POST porte l'en-tête
 * {@code Idempotency-Key} et a déjà été traitée pour cet utilisateur, la réponse d'origine est renvoyée
 * sans réexécuter l'opération. Seules les opérations de la liste blanche sont concernées : la paie, les
 * validations et les permissions ne sont jamais synchronisées depuis le mode hors ligne.
 */
public class IdempotenceFilter extends OncePerRequestFilter {

    public static final String ENTETE = "Idempotency-Key";
    static final List<String> OPERATIONS_HORS_LIGNE = List.of("/api/conges", "/api/notes-frais");

    private final JdbcTemplate jdbc;

    public IdempotenceFilter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        String chemin = request.getRequestURI().substring(request.getContextPath().length());
        return !"POST".equals(request.getMethod()) || request.getHeader(ENTETE) == null
            || !OPERATIONS_HORS_LIGNE.contains(chemin);
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
                                    @NonNull FilterChain chain) throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String cle = request.getHeader(ENTETE).trim();
        if (!(auth != null && auth.getPrincipal() instanceof UserPrincipal p) || !cle.matches("^[A-Za-z0-9-]{8,100}$")) {
            if (auth != null && auth.getPrincipal() instanceof UserPrincipal) {
                response.sendError(400, "Idempotency-Key invalide.");
                return;
            }
            chain.doFilter(request, response);
            return;
        }
        long utilisateur = p.getUtilisateur().getId();
        String requete = request.getMethod() + " " + request.getRequestURI();
        int reserve = jdbc.update("INSERT INTO requetes_idempotentes (utilisateur_id, cle, requete) VALUES (?, ?, ?) "
            + "ON CONFLICT DO NOTHING", utilisateur, cle, requete);
        if (reserve == 0) {
            Map<String, Object> deja = jdbc.queryForMap(
                "SELECT requete, statut, corps FROM requetes_idempotentes WHERE utilisateur_id = ? AND cle = ?", utilisateur, cle);
            response.setContentType("application/json;charset=UTF-8");
            if (!requete.equals(deja.get("requete"))) {
                response.setStatus(422);
                response.getWriter().write("{\"status\":422,\"message\":\"Clé déjà utilisée pour une autre opération.\"}");
            } else if (deja.get("statut") == null) {
                response.setStatus(409);
                response.getWriter().write("{\"status\":409,\"message\":\"Opération en cours de traitement.\"}");
            } else {
                response.setStatus((Integer) deja.get("statut"));
                response.setHeader("Idempotent-Replay", "true");
                response.getWriter().write(String.valueOf(deja.get("corps")));
            }
            return;
        }
        ContentCachingResponseWrapper copie = new ContentCachingResponseWrapper(response);
        try {
            chain.doFilter(request, copie);
        } finally {
            int statut = copie.getStatus();
            if (statut >= 500) {
                // Erreur serveur : la clé est libérée pour permettre une nouvelle tentative.
                jdbc.update("DELETE FROM requetes_idempotentes WHERE utilisateur_id = ? AND cle = ?", utilisateur, cle);
            } else {
                jdbc.update("UPDATE requetes_idempotentes SET statut = ?, corps = ? WHERE utilisateur_id = ? AND cle = ?",
                    statut, new String(copie.getContentAsByteArray(), StandardCharsets.UTF_8), utilisateur, cle);
            }
            copie.copyBodyToResponse();
        }
    }
}
