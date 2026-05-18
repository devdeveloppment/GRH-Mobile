# Guide de déploiement — GRH-Mobile

**Version** : 1.0.0  
**Dernière mise à jour** : Mai 2026

---

## Table des matières

1. [Architecture de l'application](#1-architecture-de-lapplication)
2. [Prérequis](#2-prérequis)
3. [Déploiement local (développement)](#3-déploiement-local-développement)
4. [Déploiement en production (serveur Linux)](#4-déploiement-en-production-serveur-linux)
5. [Variables d'environnement](#5-variables-denvironnement)
6. [Build de l'application Flutter](#6-build-de-lapplication-flutter)
7. [Déploiement avec Docker Compose complet](#7-déploiement-avec-docker-compose-complet)
8. [Reverse proxy Nginx](#8-reverse-proxy-nginx)
9. [Sauvegardes PostgreSQL](#9-sauvegardes-postgresql)
10. [Surveillance et santé](#10-surveillance-et-santé)
11. [Mise à jour de l'application](#11-mise-à-jour-de-lapplication)
12. [Résolution des problèmes fréquents](#12-résolution-des-problèmes-fréquents)

---

## 1. Architecture de l'application

```
┌─────────────────────────────────────────────────┐
│               Client Flutter                     │
│   (Linux Desktop / Android / iOS / Web)         │
└────────────────────┬────────────────────────────┘
                     │ HTTP/REST (JWT)
                     ▼
┌─────────────────────────────────────────────────┐
│          Backend Spring Boot (API)               │
│   Java 17 · Spring Boot 3.3.2 · Port 8080       │
│   Flyway (migrations) · JWT Auth                 │
└────────────────────┬────────────────────────────┘
                     │ JDBC
                     ▼
┌─────────────────────────────────────────────────┐
│           PostgreSQL 15 (Docker)                 │
│   Base : grh_mobile · Port 5432                  │
│   Volume persistant : postgres_data              │
└─────────────────────────────────────────────────┘
```

**Stack technique** :
- Frontend : Flutter 3.22+ / Dart SDK 3.4+
- Backend : Java 17, Spring Boot 3.3.2, Maven
- Base de données : PostgreSQL 15
- Migrations : Flyway
- Auth : JWT (expire après 8h)
- Stockage fichiers : système de fichiers local (`uploads/photos`)

---

## 2. Prérequis

### Environnement de développement

| Logiciel | Version minimale | Commande de vérification |
|----------|-----------------|--------------------------|
| Java JDK | 17 | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Flutter SDK | 3.22+ | `flutter --version` |
| Docker | 24+ | `docker --version` |
| Docker Compose | 2.x | `docker compose version` |
| PostgreSQL client (optionnel) | 15 | `psql --version` |

### Environnement de production (serveur)

- OS : Ubuntu 22.04 LTS ou Debian 12 recommandé
- RAM : minimum 2 Go (4 Go recommandé)
- Disque : minimum 10 Go libre
- Ports ouverts : 8080 (API), 5432 (PostgreSQL, optionnel si même serveur)

---

## 3. Déploiement local (développement)

### Étape 1 — Cloner le projet

```bash
git clone <url-du-projet>
cd "PPE 302"
```

### Étape 2 — Démarrer la base de données PostgreSQL

```bash
docker compose up -d postgres
```

Vérifiez que PostgreSQL est prêt :
```bash
docker compose ps
# postgres doit être en statut "healthy"
```

### Étape 3 — Configurer les variables d'environnement (optionnel)

Créez un fichier `.env` à la racine du projet Flutter (pour l'URL de l'API) :

```env
API_BASE_URL=http://localhost:8080/api
```

Si le fichier `.env` est absent, le fichier `.env.example` est utilisé automatiquement.

### Étape 4 — Démarrer le backend

```bash
cd backend
mvn spring-boot:run
```

Le backend démarre en ~30 secondes. Attendez le message :
```
Started GrhMobileApplication in XX.XXX seconds
```

> Flyway applique automatiquement toutes les migrations SQL au démarrage.  
> Le compte administrateur `admin@grh-mobile.com` est créé automatiquement s'il n'existe pas.

### Étape 5 — Lancer l'application Flutter

Dans un nouveau terminal, depuis la racine du projet :

```bash
# Application desktop Linux
flutter run -d linux

# Application Android (émulateur ou appareil connecté)
flutter run -d android

# Application Web
flutter run -d chrome
```

---

## 4. Déploiement en production (serveur Linux)

### Étape 1 — Préparer le serveur

```bash
# Installer Java 17
sudo apt update
sudo apt install -y openjdk-17-jre-headless

# Installer Docker et Docker Compose
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Vérifier
java -version
docker --version
```

### Étape 2 — Copier les fichiers sur le serveur

```bash
# Depuis votre machine de développement
scp -r ./backend user@votre-serveur:/opt/grh-mobile/
scp ./docker-compose.yml user@votre-serveur:/opt/grh-mobile/
```

### Étape 3 — Démarrer PostgreSQL

```bash
cd /opt/grh-mobile
docker compose up -d postgres
```

### Étape 4 — Construire le JAR du backend

```bash
cd /opt/grh-mobile/backend
mvn clean package -DskipTests
```

Le JAR est généré dans `target/grh-mobile-api-1.0.0.jar`.

### Étape 5 — Lancer le backend en production

Créez un fichier de configuration d'environnement `/opt/grh-mobile/.env.prod` :

```env
DB_URL=jdbc:postgresql://localhost:5432/grh_mobile
DB_USERNAME=grh
DB_PASSWORD=VotreMotDePasseSecurise
JWT_SECRET=VotreCleSecreteLongueEtAleatoire64CaracteresMinimum
JWT_EXPIRATION_MINUTES=480
BOOTSTRAP_ADMIN_EMAIL=admin@votre-domaine.com
BOOTSTRAP_ADMIN_PASSWORD=Admin@VotreMotDePasse
SERVER_PORT=8080
UPLOAD_DIR=/opt/grh-mobile/uploads/photos
```

Lancez le backend :

```bash
mkdir -p /opt/grh-mobile/uploads/photos

source /opt/grh-mobile/.env.prod
java -jar /opt/grh-mobile/backend/target/grh-mobile-api-1.0.0.jar \
  --spring.datasource.url=$DB_URL \
  --spring.datasource.username=$DB_USERNAME \
  --spring.datasource.password=$DB_PASSWORD \
  --app.jwt.secret=$JWT_SECRET \
  --app.upload.dir=$UPLOAD_DIR \
  --server.port=$SERVER_PORT
```

### Étape 6 — Créer un service systemd (redémarrage automatique)

Créez `/etc/systemd/system/grh-mobile.service` :

```ini
[Unit]
Description=GRH-Mobile API
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/grh-mobile
EnvironmentFile=/opt/grh-mobile/.env.prod
ExecStart=/usr/bin/java \
  -XX:+UseContainerSupport \
  -XX:MaxRAMPercentage=75.0 \
  -Dspring.datasource.url=${DB_URL} \
  -Dspring.datasource.username=${DB_USERNAME} \
  -Dspring.datasource.password=${DB_PASSWORD} \
  -Dapp.jwt.secret=${JWT_SECRET} \
  -Dapp.upload.dir=${UPLOAD_DIR} \
  -jar /opt/grh-mobile/backend/target/grh-mobile-api-1.0.0.jar
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=grh-mobile

[Install]
WantedBy=multi-user.target
```

Activez et démarrez le service :

```bash
sudo systemctl daemon-reload
sudo systemctl enable grh-mobile
sudo systemctl start grh-mobile

# Vérifier le statut
sudo systemctl status grh-mobile

# Voir les logs en temps réel
sudo journalctl -u grh-mobile -f
```

---

## 5. Variables d'environnement

### Backend (Spring Boot)

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `DB_URL` | URL JDBC PostgreSQL | `jdbc:postgresql://localhost:5432/grh_mobile` |
| `DB_USERNAME` | Utilisateur PostgreSQL | `grh` |
| `DB_PASSWORD` | Mot de passe PostgreSQL | `grhpassword` |
| `DB_POOL_MAX_SIZE` | Taille max du pool de connexions | `10` |
| `JWT_SECRET` | Clé secrète JWT (min 32 caractères) | `change-me-...` |
| `JWT_EXPIRATION_MINUTES` | Durée de validité du token JWT | `480` (8h) |
| `SERVER_PORT` | Port du serveur HTTP | `8080` |
| `UPLOAD_DIR` | Répertoire des photos uploadées | `uploads/photos` |
| `AUTO_LOGOUT_MINUTES` | Délai d'inactivité avant déconnexion | `30` |
| `BOOTSTRAP_ADMIN_ENABLED` | Créer l'admin au démarrage | `true` |
| `BOOTSTRAP_ADMIN_EMAIL` | E-mail du compte admin initial | `admin@grh-mobile.com` |
| `BOOTSTRAP_ADMIN_PASSWORD` | Mot de passe du compte admin initial | `Admin@12345` |
| `BOOTSTRAP_ADMIN_RESET_PASSWORD` | Réinitialiser le mot de passe admin au démarrage | `true` |
| `CORS_ALLOWED_ORIGINS` | Origines CORS autorisées | `http://localhost:3000,...` |

### Flutter (fichier `.env`)

| Variable | Description | Exemple |
|----------|-------------|---------|
| `API_BASE_URL` | URL de base de l'API | `http://192.168.1.10:8080/api` |

> En production, remplacez `localhost` par l'adresse IP ou le nom de domaine du serveur.

---

## 6. Build de l'application Flutter

### Application Linux Desktop

```bash
flutter build linux --release
```

L'exécutable est dans :
```
build/linux/x64/release/bundle/grh_mobile
```

Pour distribuer, copiez tout le dossier `bundle/` sur la machine cible.

### Application Android (APK)

```bash
flutter build apk --release
```

L'APK est dans :
```
build/app/outputs/flutter-apk/app-release.apk
```

### Application Android (App Bundle pour Play Store)

```bash
flutter build appbundle --release
```

### Application Web

```bash
flutter build web --release
```

Les fichiers web sont dans `build/web/`. Déployez ce dossier sur un serveur web (Nginx, Apache).

---

## 7. Déploiement avec Docker Compose complet

Pour containeriser également le backend, créez un `docker-compose.prod.yml` :

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:15-alpine
    container_name: grh-mobile-postgres
    environment:
      POSTGRES_DB: grh_mobile
      POSTGRES_USER: grh
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U grh -d grh_mobile"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  api:
    image: eclipse-temurin:17-jre-alpine
    container_name: grh-mobile-api
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/grh_mobile
      DB_USERNAME: grh
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      BOOTSTRAP_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      UPLOAD_DIR: /app/uploads/photos
    ports:
      - "8080:8080"
    volumes:
      - ./backend/target/grh-mobile-api-1.0.0.jar:/app/app.jar
      - uploads_data:/app/uploads
    command: >
      java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar /app/app.jar
    restart: unless-stopped

volumes:
  postgres_data:
  uploads_data:
```

Lancez avec :
```bash
# Construire le JAR d'abord
cd backend && mvn clean package -DskipTests && cd ..

# Démarrer tous les services
DB_PASSWORD=motdepasse JWT_SECRET=clesecrete ADMIN_PASSWORD=admin \
  docker compose -f docker-compose.prod.yml up -d
```

---

## 8. Reverse proxy Nginx

En production, placez Nginx devant le backend pour gérer HTTPS et les en-têtes.

Installez Nginx :
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

Configuration `/etc/nginx/sites-available/grh-mobile` :

```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name votre-domaine.com;

    ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;

    # API Backend
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }

    # Photos uploadées
    location /uploads/ {
        proxy_pass http://localhost:8080/uploads/;
    }

    # Application Web Flutter (si déployée)
    location / {
        root /opt/grh-mobile/web;
        try_files $uri $uri/ /index.html;
    }
}
```

Activez et obtenez un certificat SSL :
```bash
sudo ln -s /etc/nginx/sites-available/grh-mobile /etc/nginx/sites-enabled/
sudo certbot --nginx -d votre-domaine.com
sudo systemctl reload nginx
```

---

## 9. Sauvegardes PostgreSQL

### Sauvegarde manuelle

```bash
# Sauvegarde complète
docker exec grh-mobile-postgres pg_dump -U grh grh_mobile > backup_$(date +%Y%m%d_%H%M).sql

# Restauration
docker exec -i grh-mobile-postgres psql -U grh grh_mobile < backup_20260518_1200.sql
```

### Sauvegarde automatique (cron)

Créez `/opt/grh-mobile/backup.sh` :

```bash
#!/bin/bash
BACKUP_DIR="/opt/grh-mobile/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

docker exec grh-mobile-postgres pg_dump -U grh grh_mobile \
  | gzip > "$BACKUP_DIR/grh_mobile_$DATE.sql.gz"

# Garder seulement les 30 derniers backups
ls -t "$BACKUP_DIR"/*.sql.gz | tail -n +31 | xargs -r rm
echo "Backup completed: grh_mobile_$DATE.sql.gz"
```

Ajoutez au cron (sauvegarde quotidienne à 2h00) :
```bash
chmod +x /opt/grh-mobile/backup.sh
crontab -e
# Ajouter la ligne :
0 2 * * * /opt/grh-mobile/backup.sh >> /var/log/grh-mobile-backup.log 2>&1
```

---

## 10. Surveillance et santé

### Endpoints de santé (Spring Actuator)

| Endpoint | Description |
|----------|-------------|
| `GET /actuator/health` | État général du service |
| `GET /actuator/info` | Informations sur l'application |
| `GET /actuator/metrics` | Métriques de performance |

Exemple de vérification :
```bash
curl http://localhost:8080/actuator/health
# Réponse attendue : {"status":"UP"}
```

### Logs en temps réel

```bash
# Avec systemd
sudo journalctl -u grh-mobile -f --since "1 hour ago"

# Avec nohup (développement)
tail -f /tmp/backend.log
```

### Vérifier que le port est ouvert

```bash
# Vérifier que le backend écoute sur 8080
lsof -i :8080

# Tester l'API
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@grh-mobile.com","password":"Admin@12345"}'
```

---

## 11. Mise à jour de l'application

### Mettre à jour le backend

```bash
# 1. Récupérer les nouvelles sources
git pull origin main

# 2. Recompiler
cd backend
mvn clean package -DskipTests

# 3. Redémarrer le service (les migrations Flyway s'appliquent automatiquement)
sudo systemctl restart grh-mobile

# 4. Vérifier
sudo systemctl status grh-mobile
curl http://localhost:8080/actuator/health
```

### Mettre à jour l'application Flutter

```bash
# 1. Récupérer les nouvelles sources
git pull origin main

# 2. Mettre à jour les dépendances
flutter pub get

# 3. Recompiler pour la cible souhaitée
flutter build linux --release   # ou android, web...
```

### Appliquer une migration SQL manuelle

Les migrations sont gérées automatiquement par Flyway. Pour ajouter une migration :
1. Créez un fichier `backend/src/main/resources/db/migration/VXX__description.sql`
2. Redémarrez le backend — Flyway applique la migration automatiquement.

> Ne modifiez jamais un fichier de migration existant. Créez toujours un nouveau fichier.

---

## 12. Résolution des problèmes fréquents

### Le port 8080 est déjà utilisé

```bash
# Trouver et tuer le processus
kill -9 $(lsof -t -i:8080)
# ou
sudo fuser -k 8080/tcp
```

### Erreur de connexion à PostgreSQL

```bash
# Vérifier que le conteneur tourne
docker ps | grep postgres

# Vérifier les logs du conteneur
docker logs grh-mobile-postgres

# Tester la connexion manuellement
docker exec -it grh-mobile-postgres psql -U grh -d grh_mobile -c "SELECT 1;"
```

### Erreur de migration Flyway

Si une migration échoue, Flyway bloque tous les démarrages suivants :

```bash
# Vérifier l'état des migrations
docker exec -it grh-mobile-postgres psql -U grh -d grh_mobile \
  -c "SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"

# En dernier recours : supprimer la migration échouée et corriger le SQL
docker exec -it grh-mobile-postgres psql -U grh -d grh_mobile \
  -c "DELETE FROM flyway_schema_history WHERE success = false;"
```

### Token JWT expiré / Erreur 401

- La session est expirée (8h). Reconnectez-vous.
- Si le problème persiste, vérifiez que `JWT_SECRET` est identique entre les redémarrages.

### Erreur 403 sur une page

- L'utilisateur connecté n'a pas le rôle requis pour cette fonctionnalité.
- Vérifiez le rôle attribué dans Administration → Utilisateurs.

### Photos non affichées

```bash
# Vérifier que le répertoire existe et est accessible
ls -la /opt/grh-mobile/uploads/photos/

# Vérifier les permissions
chmod -R 755 /opt/grh-mobile/uploads/
```

### L'application Flutter ne se connecte pas à l'API

1. Vérifiez que `API_BASE_URL` dans `.env` pointe vers la bonne adresse.
2. Sur Android/iOS, utilisez l'IP du serveur, pas `localhost`.
3. Vérifiez que le pare-feu autorise le port 8080 :
   ```bash
   sudo ufw allow 8080/tcp
   ```

---

*Pour toute question ou assistance, contactez l'équipe technique.*
