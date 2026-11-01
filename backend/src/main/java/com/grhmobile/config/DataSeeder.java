package com.grhmobile.config;

import java.time.OffsetDateTime;

import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.util.PasswordGenerator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import com.grhmobile.tenant.TenantContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Création du compte administrateur initial, quel que soit le profil.
 * Les données de démonstration sont dans {@link DemoDataSeeder} (profil « demo » uniquement).
 */
@Configuration
public class DataSeeder {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    @Bean
    @Order(1)
    CommandLineRunner bootstrapAdmin(
        UtilisateurRepository utilisateurRepository,
        PasswordEncoder passwordEncoder,
        AppProperties appProperties,
        @Value("${app.platform-admin.email:}") String platformEmail,
        @Value("${app.platform-admin.password:}") String platformPassword
    ) {
        // Comptes créés dans l'entreprise n° 1 (entreprise de l'éditeur de la plateforme).
        return args -> TenantContext.executer(1L, () -> {
            ensureBootstrapAdmin(utilisateurRepository, passwordEncoder, appProperties.getBootstrapAdmin());
            ensurePlatformAdmin(utilisateurRepository, passwordEncoder, platformEmail, platformPassword);
        });
    }

    /** Super-administrateur de la plateforme SaaS (gestion des entreprises), si configuré. */
    private void ensurePlatformAdmin(UtilisateurRepository repository, PasswordEncoder encoder, String email, String password) {
        if (email == null || email.isBlank()) {
            return;
        }
        boolean existe = TenantContext.systeme(() -> repository.findByEmailIgnoreCase(email).isPresent());
        if (existe) {
            return;
        }
        Utilisateur u = new Utilisateur();
        u.setEmail(email.trim().toLowerCase());
        u.setNom("Plateforme");
        u.setPrenom("Super");
        u.setRole(Role.SUPER_ADMIN);
        u.setActif(true);
        u.setDateCreation(OffsetDateTime.now());
        String p = password;
        if (p == null || p.isBlank()) {
            p = PasswordGenerator.temporaryPassword();
            u.setDoitChangerMotDePasse(true);
            log.warn("Super-administrateur {} créé avec le mot de passe temporaire : {}", email, p);
        }
        u.setMotDePasse(encoder.encode(p));
        repository.save(u);
    }

    private Utilisateur ensureBootstrapAdmin(
        UtilisateurRepository repository,
        PasswordEncoder encoder,
        AppProperties.BootstrapAdmin config
    ) {
        if (!config.isEnabled()) {
            return null;
        }

        Utilisateur admin = repository.findByEmailIgnoreCase(config.getEmail())
            .orElseGet(Utilisateur::new);

        boolean isNewUser = admin.getId() == null;
        admin.setNom(config.getNom());
        admin.setPrenom(config.getPrenom());
        admin.setEmail(config.getEmail());
        admin.setRole(Role.ADMIN);
        admin.setActif(true);

        if (isNewUser) {
            admin.setDateCreation(OffsetDateTime.now());
        }

        if (isNewUser || config.isResetPasswordOnStartup()) {
            String password = config.getPassword();
            if (password == null || password.isBlank()) {
                password = PasswordGenerator.temporaryPassword();
                log.warn("Compte administrateur initial {} créé avec le mot de passe temporaire : {} "
                    + "(changement obligatoire à la première connexion).", config.getEmail(), password);
                admin.setDoitChangerMotDePasse(true);
            }
            admin.setMotDePasse(encoder.encode(password));
        }

        return repository.save(admin);
    }
}
