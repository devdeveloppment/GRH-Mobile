# GRH-Mobile

Template full stack pour une plateforme GRH B2B/SaaS destinée aux PME togolaises.

## Contenu du repo

- `lib/` : application Flutter mobile et web
- `backend/` : API Spring Boot sécurisée par JWT
- `docker-compose.yml` : base PostgreSQL locale
- `docs/architecture.md` : vue d'ensemble technique

## Comptes de démonstration

Mot de passe pour tous les comptes seedés : `ChangeMe@123`

- `admin@grh-mobile.com` → `ADMIN`
- `rh@grh-mobile.com` → `RH_MANAGER`
- `employee@grh-mobile.com` → `EMPLOYEE`
- `direction@grh-mobile.com` → `DIRECTION`

## Lancer la base PostgreSQL

```bash
docker compose up -d postgres
```

## Lancer le backend Spring Boot

```bash
cd backend
mvn spring-boot:run
```

Swagger sera disponible sur `http://localhost:8080/swagger-ui.html`.

## Lancer le frontend Flutter

```bash
flutter pub get
flutter run -d chrome
```

Pense à créer un fichier `.env` côté Flutter avec :

```env
API_BASE_URL=http://localhost:8080/api
CERT_SHA256_PINS=
AUTO_LOGOUT_MINUTES=30
```
# GRH-Mobile
