package com.grhmobile.config;

import java.time.OffsetDateTime;

import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.util.PasswordGenerator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
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
        AppProperties appProperties
    ) {
        return args -> ensureBootstrapAdmin(utilisateurRepository, passwordEncoder, appProperties.getBootstrapAdmin());
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
