#!/bin/bash

# 🔍 Verification Script - Photo Upload Implementation
# Run this script to verify all changes are in place

echo "═══════════════════════════════════════════════════════════════"
echo "🔍 GRH-Mobile Photo Upload - Implementation Verification"
echo "═══════════════════════════════════════════════════════════════"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKEND_PATH="backend/src/main/java/com/grhmobile"
FRONTEND_PATH="lib"

# Function to check file
check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description (NOT FOUND: $file)"
        return 1
    fi
}

# Function to check pattern in file
check_pattern() {
    local file=$1
    local pattern=$2
    local description=$3
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        return 1
    fi
}

echo ""
echo "📦 BACKEND VERIFICATION"
echo "───────────────────────────────────────────────────────────────"

# Backend checks
check_file "$BACKEND_PATH/entity/Utilisateur.java" "1. Utilisateur entity exists"
check_pattern "$BACKEND_PATH/entity/Utilisateur.java" "photoUrl" "   - photoUrl field added"
check_pattern "$BACKEND_PATH/entity/Utilisateur.java" "getPhotoUrl" "   - getPhotoUrl() method exists"

check_file "$BACKEND_PATH/controller/ProfileController.java" "2. ProfileController created"
check_pattern "$BACKEND_PATH/controller/ProfileController.java" "uploadPhoto" "   - uploadPhoto() method exists"
check_pattern "$BACKEND_PATH/controller/ProfileController.java" "deletePhoto" "   - deletePhoto() method exists"

check_file "$BACKEND_PATH/dto/auth/UserDto.java" "3. Auth UserDto updated"
check_pattern "$BACKEND_PATH/dto/auth/UserDto.java" "photoUrl" "   - photoUrl field added"

check_file "$BACKEND_PATH/dto/admin/UserDto.java" "4. Admin UserDto updated"
check_pattern "$BACKEND_PATH/dto/admin/UserDto.java" "photoUrl" "   - photoUrl field added"

check_file "backend/src/main/resources/application.yml" "5. application.yml configured"
check_pattern "backend/src/main/resources/application.yml" "static-locations" "   - static-locations configured"
check_pattern "backend/src/main/resources/application.yml" "app.upload.dir" "   - upload.dir configured"

check_file "backend/src/main/resources/db/migration/V10__add_photo_url_to_utilisateur.sql" "6. Flyway V10 migration created"
check_pattern "backend/src/main/resources/db/migration/V10__add_photo_url_to_utilisateur.sql" "photo_url" "   - photo_url column migration exists"

echo ""
echo "📱 FRONTEND VERIFICATION"
echo "───────────────────────────────────────────────────────────────"

# Frontend checks
check_file "$FRONTEND_PATH/shared/models/utilisateur.dart" "7. Utilisateur model updated"
check_pattern "$FRONTEND_PATH/shared/models/utilisateur.dart" "photoUrl" "   - photoUrl field added"

check_file "$FRONTEND_PATH/core/providers/profile_provider.dart" "8. profile_provider updated"
check_pattern "$FRONTEND_PATH/core/providers/profile_provider.dart" "MultipartFile" "   - MultipartFile import added"
check_pattern "$FRONTEND_PATH/core/providers/profile_provider.dart" "FormData" "   - FormData usage added"

check_file "$FRONTEND_PATH/features/profile/profile_screen.dart" "9. ProfileScreen created"
check_pattern "$FRONTEND_PATH/features/profile/profile_screen.dart" "ImagePicker" "   - ImagePicker integration"
check_pattern "$FRONTEND_PATH/features/profile/profile_screen.dart" "updatePhoto" "   - Photo upload handler"

check_file "$FRONTEND_PATH/shared/widgets/grh_sidebar.dart" "10. grh_sidebar updated"
check_pattern "$FRONTEND_PATH/shared/widgets/grh_sidebar.dart" "InkWell" "   - Avatar made clickable"
check_pattern "$FRONTEND_PATH/shared/widgets/grh_sidebar.dart" "backgroundImage" "   - Image display added"

check_file "$FRONTEND_PATH/core/constants/app_routes.dart" "11. app_routes updated"
check_pattern "$FRONTEND_PATH/core/constants/app_routes.dart" "profile" "   - /profile route added"

check_file "$FRONTEND_PATH/core/routing/app_router.dart" "12. app_router updated"
check_pattern "$FRONTEND_PATH/core/routing/app_router.dart" "ProfileScreen" "   - ProfileScreen import added"
check_pattern "$FRONTEND_PATH/core/routing/app_router.dart" "AppRoutes.profile" "   - GoRoute configured"

echo ""
echo "📄 DOCUMENTATION VERIFICATION"
echo "───────────────────────────────────────────────────────────────"

check_file "PHOTO_UPLOAD_IMPLEMENTATION.md" "13. Implementation guide"
check_file "DEPLOYMENT_CHECKLIST.md" "14. Deployment checklist"
check_file "API_TESTING_GUIDE.md" "15. API testing guide"
check_file "IMPLEMENTATION_SUMMARY.md" "16. Implementation summary"

echo ""
echo "═══════════════════════════════════════════════════════════════"

# Count checks
total_checks=$(grep -c "✓\|✗" <<< "$(echo -e "${GREEN}✓${NC}\n${RED}✗${NC}")" || true)

echo ""
echo "📊 MIGRATION FILES"
echo "───────────────────────────────────────────────────────────────"

if [ -d "backend/src/main/resources/db/migration" ]; then
    echo "Migration files in order:"
    ls -1 backend/src/main/resources/db/migration/V*.sql | while read f; do
        basename "$f"
    done
else
    echo -e "${RED}✗${NC} Migration directory not found"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔧 QUICK START COMMANDS"
echo "───────────────────────────────────────────────────────────────"

echo ""
echo "Backend:"
echo "  mvn clean install"
echo "  mvn spring-boot:run"
echo ""

echo "Frontend:"
echo "  flutter pub get"
echo "  flutter run"
echo ""

echo "Database verification:"
echo "  SELECT column_name FROM information_schema.columns"
echo "  WHERE table_name='utilisateurs' AND column_name='photo_url';"
echo ""

echo "API Testing:"
echo "  curl -X POST http://localhost:8080/api/profile/photo \\"
echo "    -H 'Authorization: Bearer <TOKEN>' \\"
echo "    -F 'photo=@/path/to/image.jpg'"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "✅ Verification Complete!"
echo "═══════════════════════════════════════════════════════════════"
