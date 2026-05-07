# 🔬 API Testing Guide - Photo Upload

## Postman/cURL Tests

### 1️⃣ Login (obtenir le JWT token)

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123"
  }'
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "nom": "Dupont",
    "prenom": "Jean",
    "email": "test@example.com",
    "role": "EMPLOYEE",
    "actif": true,
    "dateCreation": "2026-01-15T10:00:00",
    "photoUrl": null
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 2️⃣ Upload Photo

```bash
# Avec cURL
curl -X POST http://localhost:8080/api/profile/photo \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -F "photo=@/path/to/image.jpg"

# Avec Postman:
# 1. POST http://localhost:8080/api/profile/photo
# 2. Headers: Authorization: Bearer <TOKEN>
# 3. Body → form-data
#    - Key: photo (type: File)
#    - Value: select image file
# 4. Send
```

**Success Response (200):**
```json
{
  "photoUrl": "/uploads/photos/1.jpg",
  "message": "Photo uploadée avec succès"
}
```

**Error Response (400):**
```json
{
  "error": "Le fichier doit être une image"
}
```

**Error Response (401):**
```json
{
  "error": "Utilisateur non authentifié"
}
```

### 3️⃣ Delete Photo

```bash
curl -X DELETE http://localhost:8080/api/profile/photo \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

**Success Response (200):**
```json
{
  "message": "Photo supprimée avec succès"
}
```

### 4️⃣ Verify Upload (Check Database)

```bash
# SQL
SELECT id, nom, prenom, email, photo_url 
FROM utilisateurs 
WHERE id = 1;
```

**Output:**
```
 id │  nom   │ prenom │ email              │ photo_url
────┼────────┼────────┼────────────────────┼──────────────────────
  1 │ Dupont │ Jean   │ test@example.com   │ /uploads/photos/1.jpg
```

### 5️⃣ Verify File Exists

```bash
# Check file system
ls -la uploads/photos/1.jpg

# On Linux/Mac
file uploads/photos/1.jpg

# Check permissions
stat uploads/photos/1.jpg
```

---

## Postman Collection (JSON)

Save as `grh-mobile-api.postman_collection.json`:

```json
{
  "info": {
    "name": "GRH-Mobile API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "url": "{{BASE_URL}}/api/auth/login",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"admin@grh.com\",\n  \"password\": \"AdminPassword123\"\n}"
            }
          }
        }
      ]
    },
    {
      "name": "Profile Photo",
      "item": [
        {
          "name": "Upload Photo",
          "request": {
            "method": "POST",
            "url": "{{BASE_URL}}/api/profile/photo",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{JWT_TOKEN}}"
              }
            ],
            "body": {
              "mode": "formdata",
              "formdata": [
                {
                  "key": "photo",
                  "type": "file",
                  "src": "/path/to/photo.jpg"
                }
              ]
            }
          }
        },
        {
          "name": "Delete Photo",
          "request": {
            "method": "DELETE",
            "url": "{{BASE_URL}}/api/profile/photo",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{JWT_TOKEN}}"
              }
            ]
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "BASE_URL",
      "value": "http://localhost:8080"
    },
    {
      "key": "JWT_TOKEN",
      "value": ""
    }
  ]
}
```

---

## cURL Command Shortcuts

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
EMAIL="test@example.com"
PASSWORD="TestPassword123"
PHOTO_PATH="./test-photo.jpg"

# 1. Login and extract token
TOKEN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  | jq -r '.token')

echo "Token: $TOKEN"

# 2. Upload photo
echo "Uploading photo..."
curl -X POST $BASE_URL/api/profile/photo \
  -H "Authorization: Bearer $TOKEN" \
  -F "photo=@$PHOTO_PATH" \
  | jq

# 3. Delete photo
echo "Deleting photo..."
curl -X DELETE $BASE_URL/api/profile/photo \
  -H "Authorization: Bearer $TOKEN" \
  | jq
```

---

## Flutter API Testing

### Using Dio Directly in Code

```dart
import 'package:dio/dio.dart';

Future<void> testPhotoUpload() async {
  final dio = Dio();
  
  // 1. Login
  final loginRes = await dio.post(
    'http://localhost:8080/api/auth/login',
    data: {
      'email': 'test@example.com',
      'password': 'TestPassword123'
    },
  );
  
  String token = loginRes.data['token'];
  
  // 2. Upload photo
  final formData = FormData.fromMap({
    'photo': await MultipartFile.fromFile(
      './test-photo.jpg',
      filename: 'test.jpg',
    ),
  });
  
  final uploadRes = await dio.post(
    'http://localhost:8080/api/profile/photo',
    data: formData,
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  
  print('Upload response: ${uploadRes.data}');
  
  // 3. Delete photo
  final deleteRes = await dio.delete(
    'http://localhost:8080/api/profile/photo',
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  
  print('Delete response: ${deleteRes.data}');
}
```

---

## Network Tab Inspection

### In Flutter DevTools

1. Open DevTools: `flutter pub global activate devtools && devtools`
2. Go to **Network** tab
3. Perform actions in app
4. Check requests:

```
POST /api/profile/photo
Status: 200 OK
Method: POST
Headers:
  Authorization: Bearer eyJhbGciOi...
  Content-Type: multipart/form-data; boundary=...
Body (form-data):
  photo: [binary data] (filename: photo.jpg)
Response:
  {
    "photoUrl": "/uploads/photos/1.jpg",
    "message": "Photo uploadée avec succès"
  }
```

---

## Load Testing

### Using Apache Bench

```bash
# Simple request test
ab -n 100 -c 10 \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/profile/photo

# With POST data (for load testing)
# Note: ab doesn't support multipart, use Apache JMeter for realistic tests
```

### Using Apache JMeter

1. Create Test Plan
2. Add Thread Group (100 users, 10 requests)
3. Add HTTP Request Sampler:
   - Method: POST
   - URL: http://localhost:8080/api/profile/photo
   - Files Upload: photo.jpg
4. Add HTTP Header Manager:
   - Authorization: Bearer {token}
5. Run and check results

---

## Performance Metrics

Expected metrics for single photo upload:

| Metric | Expected | Status |
|--------|----------|--------|
| Upload time (1MB) | < 1s | ✓ |
| Database update | < 100ms | ✓ |
| Total latency | < 2s | ✓ |
| Peak memory | < 50MB | ✓ |
| CPU usage | < 10% | ✓ |

---

## Debugging Backend

### Enable SQL Logging

In `application.yml`:
```yaml
spring:
  jpa:
    properties:
      hibernate:
        format_sql: true
        generate_statistics: true
  logging:
    level:
      org.hibernate.SQL: DEBUG
      org.hibernate.type.descriptor.sql.BasicBinder: TRACE
```

### Check Logs

```bash
# Follow application logs
tail -f logs/grh-mobile.log | grep -i "photo\|profile\|upload"

# Check for errors
grep -i "error\|exception" logs/grh-mobile.log
```

---

## Mock Data for Testing

### Create Test User

```sql
INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe, role, actif, date_creation)
VALUES (
  'Test',
  'User',
  'test@example.com',
  '$2a$10$...',  -- bcrypt hash of "TestPassword123"
  'EMPLOYEE',
  true,
  NOW()
);
```

### Create Test Images

```bash
# Create a small test image (100x100 PNG)
convert -size 100x100 xc:blue test-photo.jpg

# Create larger test image (1024x768)
convert -size 1024x768 gradient: test-large.jpg

# Using ffmpeg
ffmpeg -f lavfi -i color=blue:s=100x100 -frames:v 1 test-photo.jpg
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: grh_mobile_test
          POSTGRES_PASSWORD: test
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-java@v2
        with:
          java-version: '21'
      - name: Run tests
        run: mvn test -DDB_URL=jdbc:postgresql://postgres:5432/grh_mobile_test
      - name: Test API endpoints
        run: |
          mvn spring-boot:run &
          sleep 10
          bash ./test-api.sh
```

---

## Success Criteria

✅ API responds with 200 OK on successful upload  
✅ File physically saved to `uploads/photos/{userId}.jpg`  
✅ Database updated with `photo_url`  
✅ JWT authentication required  
✅ Image type validation working  
✅ File size limit enforced (10MB)  
✅ Flutter app displays uploaded photo  
✅ Sidebar avatar updated  
✅ Photo persists after app restart  

---

**Last Updated:** 6 mai 2026
