# 📸 Photo Upload Feature - Developer Guide

> Quick reference for developers implementing the photo upload feature in GRH-Mobile

---

## 🚀 Quick Start

### Backend

```bash
# 1. Compile
mvn clean install

# 2. Run
mvn spring-boot:run

# 3. Database migration
# V10__add_photo_url_to_utilisateur.sql runs automatically
```

### Frontend

```bash
# 1. Get dependencies
flutter pub get

# 2. Run app
flutter run
```

---

## 📋 Feature Overview

### What Was Built

- Photo upload endpoint: `POST /api/profile/photo`
- Photo deletion endpoint: `DELETE /api/profile/photo`
- Profile screen with avatar picker
- Sidebar avatar as clickable profile shortcut
- Multipart form data handling
- Image compression (Flutter side)
- Database schema update (V10 migration)

### Key Files

**Backend (6 files):**
```
controller/ProfileController.java (150 lines)
entity/Utilisateur.java (added 4 lines)
dto/auth/UserDto.java (added 1 field)
dto/admin/UserDto.java (added 1 field)
resources/application.yml (added 5 lines)
resources/db/migration/V10__...sql (1 line)
```

**Frontend (6 files):**
```
features/profile/profile_screen.dart (250 lines)
core/providers/profile_provider.dart (added 40 lines)
shared/models/utilisateur.dart (added 1 field)
shared/widgets/grh_sidebar.dart (updated interaction)
core/constants/app_routes.dart (added 1 line)
core/routing/app_router.dart (added 2 lines)
```

---

## 🔌 API Integration

### Upload Photo

```dart
// In Flutter
final formData = FormData.fromMap({
  'photo': await MultipartFile.fromFile(filePath),
});
await dio.post('/profile/photo', data: formData);
```

```java
// In Spring Boot
@PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<Map<String, Object>> uploadPhoto(
    @RequestParam("photo") MultipartFile photo,
    Authentication authentication) { ... }
```

### Delete Photo

```dart
await dio.delete('/profile/photo');
```

```java
@DeleteMapping("/photo")
public ResponseEntity<Map<String, Object>> deletePhoto(
    Authentication authentication) { ... }
```

---

## 🧪 Testing

### Unit Test Example (Backend)

```java
@Test
void testPhotoUploadValidation() {
    MockMultipartFile photo = new MockMultipartFile(
        "photo", "test.jpg", "image/jpeg", "data".getBytes());
    
    ResponseEntity<?> response = controller.uploadPhoto(photo, auth);
    
    assertEquals(200, response.getStatusCodeValue());
    assertTrue(response.getBody().toString().contains("photoUrl"));
}
```

### Widget Test Example (Frontend)

```dart
testWidgets('Profile screen photo upload', (tester) async {
    await tester.pumpWidget(const App());
    
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    
    // Verify upload happened
    expect(find.byType(CircularProgressIndicator), findsWidgets);
});
```

---

## 🔐 Security Notes

- ✅ JWT authentication required
- ✅ Image MIME type validation
- ✅ File size limit (10MB)
- ✅ Client-side compression
- ✅ Filename based on userId (not user input)

**Security headers to add in production:**

```yaml
spring:
  security:
    headers:
      cache-control: no-cache
      x-content-type-options: nosniff
      x-frame-options: deny
```

---

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **401 Unauthorized** | Token expired, user not authenticated, token not in Authorization header |
| **400 Bad Request** | File not image type, file too large, multipart not properly formatted |
| **Photo not saving** | Check `uploads/photos` directory exists and writable, check `UPLOAD_DIR` env var |
| **Avatar not displaying** | Verify `photoUrl` field populated in DB, check URL format, network image loading |
| **"File not found" after upload** | Directory permissions issue, relative vs absolute path problem |

---

## 📦 File Structure

```
Backend:
├── entity/
│   └── Utilisateur.java              ← Entity +photoUrl
├── controller/
│   └── ProfileController.java        ← Upload/Delete endpoints
├── dto/
│   ├── auth/UserDto.java            ← +photoUrl
│   └── admin/UserDto.java           ← +photoUrl
└── resources/
    ├── application.yml              ← Config
    └── db/migration/
        └── V10__add_photo_url_...   ← DB migration

Frontend:
├── features/profile/
│   └── profile_screen.dart          ← UI Screen
├── core/
│   ├── providers/
│   │   └── profile_provider.dart    ← Upload logic
│   ├── constants/
│   │   └── app_routes.dart          ← Routes
│   └── routing/
│       └── app_router.dart          ← Navigation
├── shared/
│   ├── models/
│   │   └── utilisateur.dart         ← Model
│   └── widgets/
│       └── grh_sidebar.dart         ← Sidebar
└── pubspec.yaml                     ← Deps (already has image_picker)
```

---

## 🚀 Deployment Steps

### Development
```bash
# Backend
mvn spring-boot:run

# Frontend
flutter run -d chrome  # or your device
```

### Production
```bash
# Backend
mvn clean install -P production
java -jar target/grh-mobile-api.jar

# Frontend
flutter build apk --release
flutter build ipa --release
flutter build web --release
```

### Environment Variables

```bash
# Backend
export DB_URL=jdbc:postgresql://db:5432/grh_mobile
export DB_USERNAME=grh
export DB_PASSWORD=secure_password
export UPLOAD_DIR=/var/grh-mobile/uploads/photos
export JWT_SECRET=your_secret_key_here
```

---

## 📊 API Response Examples

### Success Upload (200)
```json
{
  "photoUrl": "/uploads/photos/1.jpg",
  "message": "Photo uploadée avec succès"
}
```

### Success Delete (200)
```json
{
  "message": "Photo supprimée avec succès"
}
```

### Error - No Auth (401)
```json
{
  "error": "Utilisateur non authentifié"
}
```

### Error - Invalid Type (400)
```json
{
  "error": "Le fichier doit être une image"
}
```

---

## 🔄 Data Flow

```
User Action
  ↓
UI: Click avatar
  ↓
image_picker dialog
  ↓
Select image (camera/gallery)
  ↓
Compress image (800x800, 85% quality)
  ↓
Flutter: POST /profile/photo with FormData
  ↓
Spring Boot: Receive, validate, save file
  ↓
Update Utilisateur.photoUrl in DB
  ↓
Return photoUrl in response
  ↓
Flutter: Invalidate profileProvider
  ↓
UI: Refresh, show SnackBar
  ↓
Done
```

---

## 💾 Database Schema

**Before:**
```sql
CREATE TABLE utilisateurs (
  id BIGSERIAL PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  mot_de_passe VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  actif BOOLEAN DEFAULT true,
  date_creation TIMESTAMP NOT NULL,
  ...
);
```

**After V10 Migration:**
```sql
ALTER TABLE utilisateurs ADD COLUMN photo_url VARCHAR(500);
```

---

## 🔗 Related Documentation

- [`PHOTO_UPLOAD_IMPLEMENTATION.md`](./PHOTO_UPLOAD_IMPLEMENTATION.md) - Detailed implementation
- [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md) - Pre-deployment checklist
- [`API_TESTING_GUIDE.md`](./API_TESTING_GUIDE.md) - API testing with cURL/Postman
- [`IMPLEMENTATION_SUMMARY.md`](./IMPLEMENTATION_SUMMARY.md) - High-level summary

---

## 👥 Contributing

When extending this feature:

1. Update database schema via new Flyway migration (V11, V12, etc.)
2. Ensure JWT authentication on all endpoints
3. Validate file types before processing
4. Compress images on client side
5. Add appropriate error handling
6. Update documentation

---

## 📝 Commit Messages

```
feat: Add photo upload for user profiles

- Add photoUrl field to Utilisateur entity
- Create ProfileController with upload/delete endpoints
- Implement multipart form data handling
- Add ProfileScreen with image picker
- Make sidebar avatar clickable
- Add V10 migration for database
- Update DTOs to include photoUrl

Closes #ISSUE_NUMBER
```

---

## 🎯 Performance Targets

- Image compression: < 100ms (Flutter)
- HTTP upload: < 1s (1MB image)
- Database update: < 100ms
- UI refresh: < 500ms

---

## 📞 Support

For issues:
1. Check `API_TESTING_GUIDE.md` for debugging
2. Review backend logs for errors
3. Check network tab in Flutter DevTools
4. Verify database migration ran (V10)
5. Confirm directory permissions

---

**Last Updated:** 6 mai 2026  
**Version:** 1.0.0  
**Status:** ✅ Ready for Production
