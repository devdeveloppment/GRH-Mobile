package com.grhmobile.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Jwt jwt = new Jwt();
    private final Cors cors = new Cors();
    private final Aws aws = new Aws();
    private final BootstrapAdmin bootstrapAdmin = new BootstrapAdmin();

    public Jwt getJwt() {
        return jwt;
    }

    public Cors getCors() {
        return cors;
    }

    public Aws getAws() {
        return aws;
    }

    public BootstrapAdmin getBootstrapAdmin() {
        return bootstrapAdmin;
    }

    public static class Jwt {
        private String secret = "";
        private long accessTokenExpirationMinutes = 480;
        private long inactivityTimeoutMinutes = 30;

        public String getSecret() {
            return secret;
        }

        public void setSecret(String secret) {
            this.secret = secret;
        }

        public long getAccessTokenExpirationMinutes() {
            return accessTokenExpirationMinutes;
        }

        public void setAccessTokenExpirationMinutes(long accessTokenExpirationMinutes) {
            this.accessTokenExpirationMinutes = accessTokenExpirationMinutes;
        }

        public long getInactivityTimeoutMinutes() {
            return inactivityTimeoutMinutes;
        }

        public void setInactivityTimeoutMinutes(long inactivityTimeoutMinutes) {
            this.inactivityTimeoutMinutes = inactivityTimeoutMinutes;
        }
    }

    public static class Cors {
        private List<String> allowedOrigins = new ArrayList<>(List.of(
            "http://localhost:3000",
            "http://localhost:5173",
            "http://localhost:8080",
            "http://localhost:8081",
            "http://localhost:4200"
        ));
        private List<String> allowedOriginPatterns = new ArrayList<>(List.of(
            "http://localhost:*",
            "http://127.0.0.1:*"
        ));

        public List<String> getAllowedOrigins() {
            return allowedOrigins;
        }

        public void setAllowedOrigins(List<String> allowedOrigins) {
            this.allowedOrigins = allowedOrigins;
        }

        public List<String> getAllowedOriginPatterns() {
            return allowedOriginPatterns;
        }

        public void setAllowedOriginPatterns(List<String> allowedOriginPatterns) {
            this.allowedOriginPatterns = allowedOriginPatterns;
        }
    }

    public static class Aws {
        private String region = "eu-west-3";
        private String s3Bucket = "grh-mobile-documents";
        private String cloudFrontDomain = "";

        public String getRegion() {
            return region;
        }

        public void setRegion(String region) {
            this.region = region;
        }

        public String getS3Bucket() {
            return s3Bucket;
        }

        public void setS3Bucket(String s3Bucket) {
            this.s3Bucket = s3Bucket;
        }

        public String getCloudFrontDomain() {
            return cloudFrontDomain;
        }

        public void setCloudFrontDomain(String cloudFrontDomain) {
            this.cloudFrontDomain = cloudFrontDomain;
        }
    }

    public static class BootstrapAdmin {
        private boolean enabled = true;
        private String nom = "Super";
        private String prenom = "Admin";
        private String email = "admin@grh-mobile.com";
        private String password = "";
        private boolean resetPasswordOnStartup = false;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getNom() {
            return nom;
        }

        public void setNom(String nom) {
            this.nom = nom;
        }

        public String getPrenom() {
            return prenom;
        }

        public void setPrenom(String prenom) {
            this.prenom = prenom;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        public boolean isResetPasswordOnStartup() {
            return resetPasswordOnStartup;
        }

        public void setResetPasswordOnStartup(boolean resetPasswordOnStartup) {
            this.resetPasswordOnStartup = resetPasswordOnStartup;
        }
    }
}
