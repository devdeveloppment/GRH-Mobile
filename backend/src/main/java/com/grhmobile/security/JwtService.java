package com.grhmobile.security;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Map;
import java.util.function.Function;

import com.grhmobile.config.AppProperties;
import com.grhmobile.entity.Utilisateur;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private static final Logger log = LoggerFactory.getLogger(JwtService.class);
    private static final String LEGACY_DEFAULT_PREFIX = "change-me";

    private final AppProperties properties;
    private final SecretKey signingKey;

    public JwtService(AppProperties properties) {
        this.properties = properties;
        this.signingKey = buildSigningKey(properties.getJwt().getSecret());
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public String generateToken(Utilisateur utilisateur) {
        Instant now = Instant.now();
        Instant expiration = now.plus(
            properties.getJwt().getAccessTokenExpirationMinutes(),
            ChronoUnit.MINUTES
        );

        return Jwts.builder()
            .subject(utilisateur.getEmail())
            .claims(Map.of(
                "role", utilisateur.getRole().name(),
                "userId", utilisateur.getId(),
                "nom", utilisateur.getNom(),
                "prenom", utilisateur.getPrenom(),
                "tv", utilisateur.getTokenVersion()
            ))
            .id(java.util.UUID.randomUUID().toString())
            .issuedAt(Date.from(now))
            .expiration(Date.from(expiration))
            .signWith(getSigningKey())
            .compact();
    }

    public boolean isTokenValid(String token, UserPrincipal userDetails) {
        Claims claims = extractAllClaims(token);
        Number version = claims.get("tv", Number.class);
        return claims.getSubject().equals(userDetails.getUsername())
            && userDetails.isEnabled()
            && claims.getExpiration().after(new Date())
            // Jeton émis avant un changement de mot de passe, de rôle, une désactivation ou une révocation.
            && version != null
            && version.intValue() == userDetails.getUtilisateur().getTokenVersion();
    }

    /** Identifiant unique (jti) et date d'expiration, pour la révocation individuelle. */
    public Claims claims(String token) {
        return extractAllClaims(token);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    private SecretKey getSigningKey() {
        return signingKey;
    }

    /**
     * Refuse les secrets absents, trop courts ou laissés à leur valeur d'exemple :
     * dans ce cas une clé aléatoire est générée (les jetons sont invalidés au redémarrage).
     */
    private static SecretKey buildSigningKey(String rawSecret) {
        if (rawSecret == null || rawSecret.isBlank() || rawSecret.startsWith(LEGACY_DEFAULT_PREFIX) || rawSecret.length() < 32) {
            log.warn("JWT_SECRET absent ou trop faible : une clé aléatoire est utilisée. "
                + "Définissez JWT_SECRET (>= 32 caractères) pour conserver les sessions entre redémarrages.");
            byte[] random = new byte[64];
            new SecureRandom().nextBytes(random);
            return Keys.hmacShaKeyFor(random);
        }
        byte[] keyBytes;
        if (rawSecret.matches("^[A-Za-z0-9+/=]+$") && rawSecret.length() >= 44) {
            keyBytes = Decoders.BASE64.decode(rawSecret);
        } else {
            keyBytes = rawSecret.getBytes(StandardCharsets.UTF_8);
        }
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
