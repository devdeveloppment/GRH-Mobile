package com.grhmobile.security;

import java.io.IOException;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import com.grhmobile.repository.EntrepriseRepository;
import com.grhmobile.tenant.TenantContext;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserPrincipalService userPrincipalService;
    private final EntrepriseRepository entrepriseRepository;
    private final RevocationJetonService revocationJetonService;

    public JwtAuthenticationFilter(JwtService jwtService, UserPrincipalService userPrincipalService,
                                   EntrepriseRepository entrepriseRepository,
                                   RevocationJetonService revocationJetonService) {
        this.revocationJetonService = revocationJetonService;
        this.entrepriseRepository = entrepriseRepository;
        this.jwtService = jwtService;
        this.userPrincipalService = userPrincipalService;
    }

    @Override
    protected void doFilterInternal(
        @NonNull HttpServletRequest request,
        @NonNull HttpServletResponse response,
        @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String jwt = authHeader.substring(7);
        String username;
        try {
            username = jwtService.extractUsername(jwt);
        } catch (Exception exception) {
            filterChain.doFilter(request, response);
            return;
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserPrincipal userPrincipal;
            try {
                // Recherche par e-mail sur toutes les entreprises (e-mail unique globalement, décision D2).
                userPrincipal = TenantContext.systeme(() -> userPrincipalService.loadUserByUsername(username));
            } catch (RuntimeException exception) {
                filterChain.doFilter(request, response);
                return;
            }
            boolean valide;
            try {
                valide = jwtService.isTokenValid(jwt, userPrincipal)
                    && !revocationJetonService.estRevoque(jwtService.claims(jwt).getId());
            } catch (RuntimeException exception) {
                valide = false;
            }
            if (valide) {
                UsernamePasswordAuthenticationToken authenticationToken =
                    new UsernamePasswordAuthenticationToken(
                        userPrincipal,
                        null,
                        userPrincipal.getAuthorities()
                    );
                authenticationToken.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
                );
                Long entrepriseId = userPrincipal.getUtilisateur().getEntrepriseId();
                boolean active = entrepriseId != null && entrepriseRepository.findById(entrepriseId)
                    .map(com.grhmobile.entity.Entreprise::estActive).orElse(false);
                if (!active) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"status\":403,\"message\":\"L'accès de votre entreprise est suspendu.\"}");
                    return;
                }
                // Toutes les requêtes de la suite sont limitées à l'entreprise de l'utilisateur.
                TenantContext.set(entrepriseId);
                SecurityContextHolder.getContext().setAuthentication(authenticationToken);
            }
        }

        filterChain.doFilter(request, response);
    }
}
