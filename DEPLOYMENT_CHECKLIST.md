# 📋 Checklist Déploiement - Upload Photo de Profil

## Backend Checklist

### 1. Code Changes
- [x] Entité `Utilisateur` - Ajout `photoUrl`
- [x] Getters/Setters `photoUrl` dans `Utilisateur`
- [x] DTO `UserDto` (auth) - Ajout `photoUrl`
- [x] DTO `UserDto` (admin) - Ajout `photoUrl`
- [x] ProfileController créé avec endpoints:
  - [x] POST `/api/profile/photo`
  - [x] DELETE `/api/profile/photo`
- [x] application.yml - Configuration statiques resources
- [x] application.yml - Configuration multipart et app.upload.dir

### 2. Database
- [x] Migration V10 créée: `V10__add_photo_url_to_utilisateur.sql`

### 3. Testing
- [ ] Build: `mvn clean install` ✓ compiles
- [ ] Démarrer l'app: `mvn spring-boot:run`
- [ ] Vérifier migration: `SELECT column_name FROM information_schema.columns WHERE table_name='utilisateurs' AND column_name='photo_url';`
- [ ] Tester upload via Postman/curl

### 4. Production Deployment
- [ ] Variables d'environnement définies:
  - [ ] `UPLOAD_DIR` (optionnel, défaut: `uploads/photos`)
  - [ ] Dossier `uploads/photos` créé et permissions 755
- [ ] Serveur statique configuré pour servir `/uploads/photos/*`
- [ ] Considérer AWS S3 pour production (optionnel)

---

## Frontend Checklist

### 1. Code Changes
- [x] Model `Utilisateur` - Ajout `photoUrl` field
- [x] Model `Utilisateur` - fromJson/toJson updated
- [x] Provider `profile_provider.dart`:
  - [x] Import `package:dio/dio.dart`
  - [x] `updatePhoto()` avec FormData multipart
  - [x] `deletePhoto()` method
- [x] Screen `profile_screen.dart` créé:
  - [x] Avatar cliquable avec `image_picker`
  - [x] Upload multipart via Dio
  - [x] SnackBar feedback
  - [x] Suppression photo
- [x] Widget `grh_sidebar.dart`:
  - [x] Zone utilisateur cliquable (InkWell)
  - [x] Avatar avec `backgroundImage` pour photo
  - [x] Navigation vers profile screen
- [x] Routes ajoutées:
  - [x] `app_routes.dart` - Constante `/profile`
  - [x] `app_router.dart` - GoRoute pour `/profile`

### 2. Dependencies
- [x] `image_picker: ^1.1.2` - Déjà présent dans pubspec.yaml
- [x] `dio: ^5.4.3` - Déjà présent
- [x] `flutter_riverpod: ^2.5.1` - Déjà présent

### 3. Testing
- [ ] `flutter pub get`
- [ ] Build: `flutter build apk` (ou web/ios)
- [ ] Tester login
- [ ] Tester clic sidebar → ProfileScreen
- [ ] Tester clic avatar → image_picker
- [ ] Tester upload image
- [ ] Tester affichage photo dans sidebar
- [ ] Tester suppression photo
- [ ] Tester navigation vers profile depuis avatar

### 4. Production Build
- [ ] `flutter build apk --release` (Android)
- [ ] `flutter build ipa --release` (iOS)
- [ ] `flutter build web --release` (Web)

---

## Integration Tests

### Scenario 1: Upload Photo
```
1. Login avec compte test
2. Sidebar cliquable → ProfileScreen
3. Avatar central cliquable
4. Galerie → Sélectionner image
5. ✓ Photo uploadée
6. ✓ Sidebar rafraîchi
7. ✓ ProfileScreen affiche nouvelle photo
```

### Scenario 2: Suppression Photo
```
1. Dans ProfileScreen
2. Bouton "Supprimer la photo" → Dialog confirm
3. ✓ Photo supprimée
4. ✓ Avatar revient aux initiales
5. ✓ Sidebar rafraîchi
```

### Scenario 3: Persistance
```
1. Upload photo
2. Fermer app
3. Redémarrer app et login
4. ✓ Photo toujours présente dans sidebar
5. ✓ Photo visible dans ProfileScreen
```

---

## Documentation

- [x] `PHOTO_UPLOAD_IMPLEMENTATION.md` - Documentation complète
- [x] Inline code comments dans controllers
- [x] Inline code comments dans providers

---

## Security Checklist

- [x] Authentification requise (Spring Security)
- [x] Validation type MIME (image/*)
- [x] Limitation taille (10MB via application.yml)
- [x] Compression image Flutter (maxWidth: 800, quality: 85)
- [x] Path traversal protection (stockage par userId)
- [x] CORS configured si nécessaire

---

## Optional Enhancements

- [ ] AWS S3 integration au lieu de disque local
- [ ] Image cropping before upload (via image_cropper package)
- [ ] Retina/high-DPI image variants
- [ ] Image optimization pipeline
- [ ] Analytics tracking pour uploads
- [ ] Retry logic pour uploads failed

---

## Troubleshooting Guide

| Issue | Solution |
|-------|----------|
| V10 migration not running | Check Flyway enabled, restart app, check logs |
| 401 Unauthorized on upload | Token JWT expired, re-login |
| File not persisted | Check directory permissions, check upload.dir path |
| Image pixelated | Increase maxWidth/maxHeight in image_picker |
| Avatar not updating | Check NetworkImage URL, verify API response |
| "Cannot upload" in flutter | Check network connectivity, check backend logs |

---

## Sign-Off

- Backend Developer: ___________  Date: _______
- Frontend Developer: ___________ Date: _______
- QA Tester: ___________ Date: _______
- Product Manager: ___________ Date: _______
