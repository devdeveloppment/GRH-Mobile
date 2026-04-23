# Architecture GRH-Mobile

## Frontend

- `Flutter 3.22+`
- `Riverpod` pour l'état global
- `GoRouter` pour la navigation déclarative
- `Dio + JWT + Secure Storage` pour l'accès API
- `Hive` pour le cache local des données récentes

## Backend

- `Spring Boot 3.3`
- `Spring Security + JWT`
- `Spring Data JPA`
- `Flyway` pour la gestion du schéma PostgreSQL
- `OpenPDF` et `Apache POI` pour les exports

## Déploiement cible AWS

- `Frontend Flutter Web` servi via `S3 + CloudFront`
- `API Spring Boot` conteneurisée sur `ECS Fargate` ou `Elastic Beanstalk`
- `PostgreSQL` sur `Amazon RDS`
- `Secrets` via `AWS Secrets Manager`
- `Observabilité` via `CloudWatch` et `/actuator/health`
