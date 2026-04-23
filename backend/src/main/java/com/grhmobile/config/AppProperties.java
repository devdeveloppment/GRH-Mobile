package com.grhmobile.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Jwt jwt = new Jwt();
    private final Cors cors = new Cors();
    private final Aws aws = new Aws();

    public Jwt getJwt() {
        return jwt;
    }

    public Cors getCors() {
        return cors;
    }

    public Aws getAws() {
        return aws;
    }

    public static class Jwt {
        private String secret = "change-me-change-me-change-me-change-me";
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

        public List<String> getAllowedOrigins() {
            return allowedOrigins;
        }

        public void setAllowedOrigins(List<String> allowedOrigins) {
            this.allowedOrigins = allowedOrigins;
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
}
