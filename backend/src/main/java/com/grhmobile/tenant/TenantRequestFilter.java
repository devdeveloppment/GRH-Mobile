package com.grhmobile.tenant;

import java.io.IOException;

import com.grhmobile.entity.Entreprise;
import com.grhmobile.repository.EntrepriseRepository;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.lang.NonNull;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * 1. Garantit qu'aucun contexte d'entreprise ne survit à une requête (nettoyage en fin de requête).
 * 2. Pour les pages publiques (offres d'emploi, candidature), résout l'entreprise depuis le
 *    paramètre {@code entreprise} (identifiant public, « defaut » si absent). Une entreprise
 *    inconnue ou suspendue ne donne accès à rien.
 * Les requêtes authentifiées reçoivent leur entreprise dans JwtAuthenticationFilter.
 */
public class TenantRequestFilter extends OncePerRequestFilter {

    private final EntrepriseRepository entrepriseRepository;

    public TenantRequestFilter(EntrepriseRepository entrepriseRepository) {
        this.entrepriseRepository = entrepriseRepository;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
                                    @NonNull FilterChain chain) throws ServletException, IOException {
        TenantContext.clear();
        try {
            if (estPublic(request)) {
                String slug = request.getParameter("entreprise");
                String cible = slug == null || slug.isBlank() ? "defaut" : slug.trim();
                entrepriseRepository.findBySlug(cible)
                    .filter(Entreprise::estActive)
                    .ifPresent(e -> TenantContext.set(e.getId()));
            }
            chain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private static boolean estPublic(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri.startsWith("/api/public/")
            || ("POST".equals(request.getMethod()) && uri.matches("/api/offres/[^/]+/candidatures(/upload)?"));
    }
}
