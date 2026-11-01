package com.grhmobile.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.stereotype.Component;

/**
 * Rend les QR codes de pointage dynamiques : le jeton permanent de l'employé est
 * accompagné d'un horodatage et d'une signature HMAC. Un QR capturé (photo,
 * capture d'écran) n'est plus utilisable au-delà de {@link #VALIDITY_SECONDS}.
 */
@Component
public class QrTokenSigner {

    public static final long VALIDITY_SECONDS = 90;

    private final byte[] key = new byte[32];

    public QrTokenSigner() {
        new SecureRandom().nextBytes(key);
    }

    /** Retourne {@code baseToken.epochSeconds.signature}. */
    public String sign(String baseToken) {
        long timestamp = Instant.now().getEpochSecond();
        return baseToken + "." + timestamp + "." + hmac(baseToken + "." + timestamp);
    }

    public Instant expiresAt(String signedToken) {
        String[] parts = signedToken.split("\\.");
        return Instant.ofEpochSecond(Long.parseLong(parts[1])).plusSeconds(VALIDITY_SECONDS);
    }

    /** Vérifie la signature et la fraîcheur ; renvoie le jeton permanent si valide. */
    public Optional<String> verify(String signedToken) {
        if (signedToken == null) {
            return Optional.empty();
        }
        String[] parts = signedToken.trim().split("\\.");
        if (parts.length != 3) {
            return Optional.empty();
        }
        long timestamp;
        try {
            timestamp = Long.parseLong(parts[1]);
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
        long age = Instant.now().getEpochSecond() - timestamp;
        if (age < -10 || age > VALIDITY_SECONDS) {
            return Optional.empty();
        }
        String expected = hmac(parts[0] + "." + parts[1]);
        if (!MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), parts[2].getBytes(StandardCharsets.UTF_8))) {
            return Optional.empty();
        }
        return Optional.of(parts[0]);
    }

    private String hmac(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Signature du QR code impossible.", exception);
        }
    }
}
