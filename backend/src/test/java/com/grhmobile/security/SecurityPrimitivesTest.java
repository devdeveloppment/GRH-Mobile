package com.grhmobile.security;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;

import com.grhmobile.config.AppProperties;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.util.PasswordGenerator;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

/** QR codes signés, mots de passe temporaires et jetons JWT. */
class SecurityPrimitivesTest {

    @Test
    void unQrSigneEstAccepteUneSeuleFoisDansSaFenetreDeValidite() {
        QrTokenSigner signer = new QrTokenSigner();
        String signed = signer.sign("base-token");
        assertThat(signer.verify(signed)).contains("base-token");
    }

    @Test
    void unQrFalsifieOuExpireEstRefuse() {
        QrTokenSigner signer = new QrTokenSigner();
        String signed = signer.sign("base-token");
        String[] parts = signed.split("\\.");

        assertThat(signer.verify("base-token")).isEmpty();                          // ancien QR statique
        assertThat(signer.verify("autre." + parts[1] + "." + parts[2])).isEmpty();   // jeton substitué
        long old = Instant.now().getEpochSecond() - QrTokenSigner.VALIDITY_SECONDS - 5;
        assertThat(signer.verify("base-token." + old + "." + parts[2])).isEmpty();   // expiré
        assertThat(new QrTokenSigner().verify(signed)).isEmpty();                   // autre clé serveur
    }

    @Test
    void lesMotsDePasseTemporairesSontRobustesEtUniques() {
        String a = PasswordGenerator.temporaryPassword();
        String b = PasswordGenerator.temporaryPassword();
        assertThat(a).hasSize(12).isNotEqualTo(b);
        assertThat(a).matches(".*[A-Z].*").matches(".*[a-z].*").matches(".*[0-9].*");
    }

    @Test
    void unSecretJwtParDefautNePermetPasDeForgerDeJeton() {
        AppProperties weak = new AppProperties();
        weak.getJwt().setSecret("change-me-change-me-change-me-change-me-change-me-1234567890");
        Utilisateur admin = new Utilisateur();
        ReflectionTestUtils.setField(admin, "id", 1L);
        admin.setEmail("admin@test.local");
        admin.setNom("Admin");
        admin.setPrenom("Test");
        admin.setRole(Role.ADMIN);

        // Deux instances avec le même secret faible utilisent des clés aléatoires différentes
        String forged = new JwtService(weak).generateToken(admin);
        JwtService server = new JwtService(weak);
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> server.extractUsername(forged))
            .isInstanceOf(io.jsonwebtoken.security.SignatureException.class);
    }

    @Test
    void unCompteDesactiveNEstPlusAccepte() {
        AppProperties props = new AppProperties();
        props.getJwt().setSecret("un-secret-de-test-suffisamment-long-pour-hs256-0123456789");
        JwtService jwt = new JwtService(props);
        Utilisateur user = new Utilisateur();
        ReflectionTestUtils.setField(user, "id", 2L);
        user.setEmail("employe@test.local");
        user.setNom("Doe");
        user.setPrenom("Jane");
        user.setRole(Role.EMPLOYEE);
        String token = jwt.generateToken(user);

        assertThat(jwt.isTokenValid(token, new UserPrincipal(user))).isTrue();
        user.setActif(false);
        assertThat(jwt.isTokenValid(token, new UserPrincipal(user))).isFalse();
    }
}
