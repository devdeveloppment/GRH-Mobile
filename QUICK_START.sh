#!/bin/bash

# GRH-Mobile Development Quick Start

echo "================================================"
echo "    GRH-Mobile - Quick Start Guide"
echo "================================================"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "================================================"
echo "    RUNNING TESTS"
echo "================================================"
echo ""

echo "🧪 Running validator tests..."
flutter test test/validators_test.dart --no-verbose

echo ""
echo "🧪 Running formatter tests..."
flutter test test/formatters_test.dart --no-verbose

echo ""
echo "🧪 Running model tests..."
flutter test test/models_test.dart --no-verbose

echo ""
echo "================================================"
echo "    PROJECT STATUS"
echo "================================================"
echo ""
echo "✅ Frontend Completion:      80-85%"
echo "✅ Backend Completion:       95%+"
echo "✅ Testing:                  30%"
echo "✅ Documentation:            80%"
echo ""

echo "📊 What's Done:"
echo "   ✅ Admin module (users, roles, settings)"
echo "   ✅ Presence management (reporting, justification)"
echo "   ✅ Payroll module (calc, export, validation)"
echo "   ✅ Reports generation"
echo "   ✅ Form validations"
echo "   ✅ Unit tests"
echo ""

echo "📋 What's Left:"
echo "   ⚠️  Linting warnings (~100 to fix)"
echo "   ⚠️  Backend integration tests"
echo "   ⚠️  UI/UX polish"
echo "   ⚠️  Performance optimization"
echo ""

echo "================================================"
echo "    QUICK COMMANDS"
echo "================================================"
echo ""
echo "# Run the app"
echo "flutter run -d chrome"
echo ""
echo "# Run all tests"
echo "flutter test"
echo ""
echo "# Check linting issues"
echo "flutter analyze"
echo ""
echo "# Generate API docs"
echo "flutter pub global run dartdoc"
echo ""

echo "================================================"
echo "    NEXT STEPS"
echo "================================================"
echo ""
echo "1. Start the backend:"
echo "   cd backend && mvn spring-boot:run"
echo ""
echo "2. Update your .env file:"
echo "   API_BASE_URL=http://localhost:8080/api"
echo ""
echo "3. Run the app:"
echo "   flutter run -d chrome"
echo ""
echo "4. Login with demo account:"
echo "   Email: admin@grh-mobile.com"
echo "   Password: ChangeMe@123"
echo ""
echo "5. Test the admin features:"
echo "   Admin → Users → Create/Edit users"
echo "   Admin → Settings → Configure system"
echo ""

echo "================================================"
echo "    DOCUMENTATION"
echo "================================================"
echo ""
echo "📖 Read these files for more info:"
echo "   - COMPLETION_REPORT.md (detailed status)"
echo "   - CHANGELOG.md (what was implemented)"
echo "   - README.md (project overview)"
echo "   - ARCHITECTURE_GUIDE.md (technical details)"
echo ""

echo "✅ Setup complete! Happy coding!"
echo ""
