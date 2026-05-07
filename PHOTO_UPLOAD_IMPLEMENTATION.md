# Upload de Photo de Profil - Guide d'Implémentation

**Date :** 6 mai 2026  
**Contexte :** Intégration Flutter + Spring Boot pour GRH-Mobile

---

## ✅ Implémentation Complète

### 1️⃣ Backend (Spring Boot)

#### A. Modification de l'entité `Utilisateur`

**Fichier :** `backend/src/main/java/com/grhmobile/entity/Utilisateur.java`

- ✅ Ajout du champ `photoUrl` (VARCHAR 500, nullable)
- ✅ Ajout des getter/setter `getPhotoUrl()` / `setPhotoUrl()`

```java
@Column(name = "photo_url", length = 500)
private String photoUrl;

public String getPhotoUrl() { return photoUrl; }
public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }
```

#### B. Migration Flyway V10

**Fichier :** `backend/src/main/resources/db/migration/V10__add_photo_url_to_utilisateur.sql`

```sql
ALTER TABLE utilisateurs ADD COLUMN photo_url VARCHAR(500);
```

#### C. Nouveau contrôleur `ProfileController`

**Fichier :** `backend/src/main/java/com/grhmobile/controller/ProfileController.java`

**Endpoints :**

- 🔷 **POST** `/api/profile/photo` - Upload photo (multipart/form-data)
  - Parameter: `photo` (MultipartFile)
  - Returns: `{ "photoUrl": "/uploads/photos/{userId}.jpg", "message": "Photo uploadée avec succès" }`
  - Sauvegarde dans: `{app.upload.dir}/{userId}.jpg`

- 🔴 **DELETE** `/api/profile/photo` - Supprimer la photo
  - Returns: `{ "message": "Photo supprimée avec succès" }`

**Validations :**
- Authentification requise (via Spring Security)
- Type MIME validé (image/*)
- Répertoire d'upload créé automatiquement

#### D. Configuration Spring

**Fichier :** `backend/src/main/resources/application.yml`

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB
  web:
    resources:
      static-locations:
        - classpath:/static/
        - file:uploads/

app:
  upload:
    dir: ${UPLOAD_DIR:uploads/photos}
```

**Variables d'environnement :**
- `UPLOAD_DIR` (optionnel) - Répertoire d'upload (défaut: `uploads/photos`)

---

### 2️⃣ Frontend (Flutter)

#### A. Mise à jour du modèle `Utilisateur`

**Fichier :** `lib/shared/models/utilisateur.dart`

- ✅ Ajout du champ `photoUrl` (nullable)
- ✅ Intégration dans `fromJson()` et `toJson()`

```dart
final String? photoUrl;

factory Utilisateur.fromJson(Map<String, dynamic> json) {
  return Utilisateur(
    // ... autres champs
    photoUrl: json['photoUrl'] as String?,
  );
}
```

#### B. Provider de profil amélioré

**Fichier :** `lib/core/providers/profile_provider.dart`

```dart
// Nouvelle méthode pour upload multipart
Future<bool> updatePhoto(String filePath) async {
  final formData = FormData.fromMap({
    'photo': await MultipartFile.fromFile(filePath, filename: 'photo.jpg'),
  });
  final response = await dio.post('/profile/photo', data: formData);
  // Rafraîchir le profil après succès
  _ref.invalidate(profileProvider);
}

// Suppression de photo
Future<bool> deletePhoto() async { ... }
```

#### C. Nouvel écran de profil

**Fichier :** `lib/features/profile/profile_screen.dart` (créé)

**Fonctionnalités :**
- 📸 Avatar cliquable → Ouvre `image_picker` (caméra ou galerie)
- ⬆️ Upload multipart vers `/api/profile/photo`
- 🔄 Rafraîchissement automatique après upload
- ✨ SnackBar de confirmation/erreur
- 🗑️ Bouton de suppression de photo

**Interaction utilisateur :**
1. Clic sur l'avatar → Dialog choix source
2. Sélection image → Compression auto (maxWidth: 800, maxHeight: 800, quality: 85)
3. Upload avec spinner
4. Rafraîchissement du profil et SnackBar de succès

#### D. Routes et navigation

**Fichier :** `lib/core/constants/app_routes.dart`
- ✅ Ajout de la constante `profile = '/profile'`

**Fichier :** `lib/core/routing/app_router.dart`
- ✅ Import du `ProfileScreen`
- ✅ Ajout de la route GoRoute pour `/profile`

#### E. Sidebar interactive

**Fichier :** `lib/shared/widgets/grh_sidebar.dart`

- ✅ Zone utilisateur maintenant cliquable (InkWell)
- ✅ Affichage de la photo via `backgroundImage` du CircleAvatar
- ✅ Fallback sur initiales si pas de photo
- ✅ Navigation vers `/profile` au clic

---

## 🔧 Prérequis

### Backend
- ✅ Spring Boot 3.x + Jakarta
- ✅ Spring Security configuré
- ✅ Flyway pour les migrations
- ✅ PostgreSQL (ou BD compatible)

### Frontend
- ✅ Flutter 3.22+
- ✅ Package `image_picker: ^1.1.2` (déjà dans pubspec.yaml)
- ✅ Package `dio: ^5.4.3` (déjà présent)
- ✅ `flutter_riverpod: ^2.5.1` (déjà présent)

---

## 📋 Tests Recommandés

### Backend
```bash
# 1. Vérifier la migration
# Après le redémarrage de l'app, vérifier que photo_url existe dans la table utilisateurs
SELECT * FROM utilisateurs LIMIT 1;

# 2. Tester l'upload
curl -X POST http://localhost:8080/api/profile/photo \
  -H "Authorization: Bearer <TOKEN>" \
  -F "photo=@/chemin/vers/image.jpg"

# 3. Vérifier le répertoire
ls -la uploads/photos/
```

### Frontend
1. Login avec un compte test
2. Cliquer sur l'avatar dans le sidebar → ProfileScreen
3. Cliquer sur l'avatar central → Image picker
4. Sélectionner une image
5. Vérifier l'upload et le rafraîchissement
6. Vérifier la photo affichée dans le sidebar et la page de profil

---

## 🔐 Sécurité

- ✅ Authentification requise (Spring Security)
- ✅ Validation du type MIME (image/*)
- ✅ Limitation taille fichier (10MB)
- ✅ Compression image côté Flutter (85% quality)
- ✅ Stockage séparé par userId

---

## 📁 Structure des fichiers

```
Backend:
├── entity/Utilisateur.java          (✅ modifiée)
├── controller/ProfileController.java (✅ créée)
├── resources/
│   ├── application.yml              (✅ modifiée)
│   └── db/migration/
│       └── V10__add_photo_url...sql (✅ créée)

Frontend:
├── features/profile/
│   └── profile_screen.dart          (✅ créée)
├── shared/models/
│   └── utilisateur.dart             (✅ modifiée)
├── core/providers/
│   └── profile_provider.dart        (✅ modifiée)
├── core/constants/
│   └── app_routes.dart              (✅ modifiée)
├── core/routing/
│   └── app_router.dart              (✅ modifiée)
└── shared/widgets/
    └── grh_sidebar.dart             (✅ modifiée)
```

---

## 🚀 Étapes de déploiement

1. **Database Migration:**
   - Redémarrer le backend → Flyway V10 exécutée automatiquement

2. **Backend:**
   - Recompiler avec `mvn clean install`
   - S'assurer que le répertoire `uploads/` est accessible en écriture

3. **Frontend:**
   - `flutter pub get` (image_picker est déjà présent)
   - `flutter run` ou rebuild

4. **Configuration Production:**
   - Définir `UPLOAD_DIR` vers un répertoire persistant
   - Configurer un CDN ou un service de stockage S3 si nécessaire
   - Implémenter les URL absolues pour `photoUrl`

---

## 🔄 Intégration S3 (Optionnel)

Pour utiliser AWS S3 à la place du disque local:

```java
// Dans ProfileController, remplacer la sauvegarde fichier par:
AmazonS3 s3 = new AmazonS3Client(credentials);
String key = "photos/" + user.getId() + ".jpg";
s3.putObject(new PutObjectRequest(bucket, key, inputStream, metadata));
String photoUrl = s3.getUrl(bucket, key).toString();
user.setPhotoUrl(photoUrl);
```

---

## ✨ Points clés d'expérience utilisateur

- 🎯 Avatar cliquable pour accès rapide au profil
- 📸 Choix source image (caméra/galerie) via dialog
- ⚡ Feedback immédiat (loading spinner, SnackBar)
- 🖼️ Affichage photo dans plusieurs contextes (sidebar, profil, cartes employé)
- 🗑️ Suppression facile de la photo

---

## 🐛 Dépannage

| Problème | Solution |
|----------|----------|
| Migration V10 non exécutée | Vérifier que Flyway est activé, redémarrer l'app |
| Upload échoue avec 401 | Vérifier le token JWT et l'authentification |
| Fichier non trouvé après upload | Vérifier les permissions du répertoire `uploads/` |
| Image pixelisée | Augmenter `maxWidth/maxHeight` dans `image_picker` |
| Avatar ne s'affiche pas | Vérifier que `photoUrl` contient l'URL correcte |

---

## 📞 Support

Pour toute question ou problème, se référer à:
- Architecture Backend: [backend/pom.xml](backend/pom.xml)
- Configuration Flutter: [pubspec.yaml](pubspec.yaml)
- Endpoints API: [ProfileController](backend/src/main/java/com/grhmobile/controller/ProfileController.java)
