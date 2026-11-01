package com.grhmobile.security;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Limitation du nombre de requêtes sur les points d'entrée exposés aux abus.
 * <p>
 * Clé : l'utilisateur authentifié s'il y en a un (changer d'adresse IP ne remet donc pas le
 * compteur à zéro), sinon l'adresse IP du client. Derrière un proxy, l'adresse réelle n'est prise
 * en compte que si {@code server.forward-headers-strategy=native} est configuré (proxy de confiance) ;
 * l'en-tête X-Forwarded-For n'est jamais lu directement, car il est falsifiable.
 * Les compteurs sont partagés entre instances (voir {@link LimiteurRequetes}).
 * La connexion est en plus limitée par compte dans {@code AuthService}.
 */
public class LimitationRequetesFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(LimitationRequetesFilter.class);
    private static final AntPathMatcher MATCHER = new AntPathMatcher();

    /** Règle : méthode (null = toutes), motif d'URL, limite, fenêtre en secondes. */
    public record Regle(String nom, String methode, String motif, int limite, int fenetreSecondes) {
    }

    public static final List<Regle> REGLES = List.of(
        new Regle("connexion", "POST", "/api/auth/login", 20, 300),
        new Regle("mot-de-passe", "PUT", "/api/profile/password", 5, 900),
        new Regle("candidature", "POST", "/api/offres/*/candidatures/**", 10, 3600),
        new Regle("candidature", "POST", "/api/offres/*/candidatures", 10, 3600),
        new Regle("public", "GET", "/api/public/**", 120, 60),
        new Regle("assistant", "POST", "/api/assistant/questions", 30, 3600),
        new Regle("export", null, "/api/reports/**", 30, 600),
        new Regle("plateforme", null, "/api/plateforme/**", 120, 60),
        new Regle("import", "POST", "/api/import/**", 20, 600)
    );

    /** Tout envoi de fichier (multipart), quel que soit le point d'entrée. */
    static final Regle UPLOAD = new Regle("upload", null, null, 30, 600);

    private final LimiteurRequetes limiteur;
    private final boolean active;

    public LimitationRequetesFilter(LimiteurRequetes limiteur, boolean active) {
        this.limiteur = limiteur;
        this.active = active;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
                                    @NonNull FilterChain chain) throws ServletException, IOException {
        if (active) {
            String chemin = request.getRequestURI().substring(request.getContextPath().length());
            String client = identifiantClient(request);
            for (Regle r : regles(request, chemin)) {
                long attente;
                try {
                    attente = limiteur.consommer(r.nom() + ":" + client, r.limite(), r.fenetreSecondes());
                } catch (RuntimeException e) {
                    // Base indisponible : l'API l'est aussi ; on ne bloque pas sur le compteur.
                    log.warn("Limitation indisponible ({}) : {}", r.nom(), e.getMessage());
                    continue;
                }
                if (attente > 0) {
                    log.warn("Limite atteinte : règle={} client={} chemin={}", r.nom(), client, chemin);
                    refuser(response, attente);
                    return;
                }
            }
        }
        chain.doFilter(request, response);
    }

    private static List<Regle> regles(HttpServletRequest request, String chemin) {
        List<Regle> applicables = new java.util.ArrayList<>();
        for (Regle r : REGLES) {
            if ((r.methode() == null || r.methode().equalsIgnoreCase(request.getMethod())) && MATCHER.match(r.motif(), chemin)) {
                applicables.add(r);
                break;
            }
        }
        String type = request.getContentType();
        if (type != null && type.toLowerCase(java.util.Locale.ROOT).startsWith("multipart/")) {
            applicables.add(UPLOAD);
        }
        return applicables;
    }

    private static String identifiantClient(HttpServletRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal p) {
            return "u" + p.getUtilisateur().getId();
        }
        return "ip" + request.getRemoteAddr();
    }

    static void refuser(HttpServletResponse response, long attenteSecondes) throws IOException {
        response.setStatus(429);
        response.setHeader("Retry-After", String.valueOf(attenteSecondes));
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"status\":429,\"message\":\"Trop de requêtes. Réessayez dans "
            + attenteSecondes + " secondes.\"}");
    }
}
