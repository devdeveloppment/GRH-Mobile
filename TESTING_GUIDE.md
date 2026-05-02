# 🧪 Guide de Test - Dashboard RH Moderne

## ✅ Pré-requis

- Flutter SDK ≥ 3.22.0
- Java 17+
- Maven 3.9+
- PostgreSQL (ou base de données existante)
- Postman ou curl (pour tester l'API)

## 🔧 Configuration

### 1. Backend - Configuration

```bash
# Naviguer au dossier backend
cd backend

# Vérifier que les credentials de DB sont dans application.yml
cat src/main/resources/application.yml

# Configuration attendue:
# spring:
#   datasource:
#     url: jdbc:postgresql://localhost:5432/grh_mobile
#     username: postgres
#     password: your_password
#   jpa:
#     hibernate:
#       ddl-auto: validate
```

### 2. Frontend - Configuration

```bash
# Naviguer au dossier root
cd ..

# Générer les models (si nécessaire)
flutter pub get

# Vérifier la configuration API
cat lib/core/services/api_service.dart
# L'URL API doit pointer vers http://localhost:8080/api
```

## 🚀 Lancement

### Backend - Démarrer le serveur

```bash
cd backend

# Option 1: Maven Spring Boot
mvn spring-boot:run

# Option 2: JAR directement (après build)
mvn clean package
java -jar target/grh-mobile-api-1.0.0.jar

# Logs attendus:
# Started GrhMobileApplication in X seconds (JVM running for Y)
# Server running on port 8080
```

### Frontend - Démarrer l'application

```bash
cd ..

# Développement web
flutter run -d web --web-port=3000

# Ou spécifier l'appareil
flutter devices
flutter run -d <device_id>

# Logs attendus:
# Flutter 3.22.0
# Running on http://localhost:3000
```

## 🧪 Tests Manuels

### 1. Test du Backend - Endpoint Dashboard

```bash
# Terminal 1: Vérifier que le backend est prêt
curl -X GET http://localhost:8080/api/dashboard/enhanced \
  -H "Authorization: Bearer <your_token>"

# Réponse attendue (200 OK):
{
  "totalEmployees": 128,
  "attendanceRate": 96.0,
  "pendingLeaves": 18,
  "payrollMass": 12450000.0,
  ...
}
```

### 2. Test du Frontend - Navigation

```bash
# Terminal 2: L'app devrait charger
# Accédez à http://localhost:3000

# Vérifiez:
1. ✅ Page de login charge
2. ✅ Se connecter avec vos credentials
3. ✅ Dashboard RH s'affiche
4. ✅ Les 4 KPI cards affichent les données
5. ✅ Les graphiques se chargent
6. ✅ Les listes de congés et anniversaires s'affichent
```

### 3. Vérifications UI

- [ ] **KPI Cards** - Valeurs s'affichent correctement
  ```
  Employés: 128 (+ 12 ce mois)
  Taux de présence: 96% (+ 4% ce mois)
  Demandes de congés: 18 (En attente)
  Masse salariale: 12.5M FCFA (Ce mois)
  ```

- [ ] **Actions Rapides** - 4 boutons visibles
  - Ajouter un employé
  - Nouvelle demande de congé
  - Générer bulletin de paie
  - Voir les rapports

- [ ] **Courbe Présences** - Graphique lissé
  - Axes étiquetés (Jan, Fév, Mar, etc.)
  - Courbe orange avec points
  - Gradient de remplissage sous la courbe

- [ ] **Donut Chart** - Répartition départements
  - Couleurs distinctes (vert, orange, bleu, gris)
  - Légende avec pourcentages
  - Total au centre

- [ ] **Demandes de Congé** - Cartes affichées
  - Avatar + nom employé
  - Dates du congé
  - Status badge avec couleur appropriée

- [ ] **Anniversaires** - Cartes affichées
  - Avatar + nom
  - Date (JJ/MM)
  - Icône cadeau 🎁

- [ ] **Responsive** - Testez sur différentes tailles
  - Desktop (≥1120px): 4 colonnes KPI
  - Tablet (768-1120px): 2 colonnes KPI
  - Mobile (<768px): 1 colonne KPI

## 📊 Données de Test

### Créer des employés de test

```bash
# Créer via API ou directement en DB
INSERT INTO employes (
  matric, prenom, nom, email, statut, date_embauche, 
  type_contrat, salaire_brut_base, date_naissance
) VALUES 
  ('EMP001', 'Aba', 'Aïsan', 'aba@grh.com', 'ACTIF', 
   '2024-06-15', 'CDI', 2000000, '1990-06-15'),
  ('EMP002', 'Mensah', 'Abouelé', 'mensah@grh.com', 'ACTIF',
   '2024-10-10', 'CDI', 1800000, '1992-06-20'),
  ('EMP003', 'Tchaka', 'Esso', 'tchaka@grh.com', 'ACTIF',
   '2024-07-03', 'CDD', 1500000, '1995-06-25');
```

### Créer des demandes de congé

```bash
INSERT INTO conges (
  employe_id, date_debut, date_fin, type, statut, motif
) VALUES
  (1, '2024-06-15', '2024-06-25', 'ANNUEL', 'EN_ATTENTE', 'Vacances'),
  (2, '2024-06-10', '2024-06-12', 'ANNUEL', 'APPROUVE', 'Congé approuvé'),
  (3, '2024-06-18', '2024-06-20', 'MALADIE', 'EN_ATTENTE', 'Maladie');
```

## 🐛 Dépannage

### Erreur: "Cannot connect to API"

```bash
# Vérifier le backend est lancé
curl http://localhost:8080/api/health

# Vérifier l'URL API dans le code
grep -r "http://localhost:8080" lib/

# Corriger si nécessaire dans api_service.dart
```

### Erreur: "Données manquantes"

```bash
# Vérifier que la base de données a des données
psql -U postgres -d grh_mobile -c "SELECT COUNT(*) FROM employes;"

# Si vide, insérer les données de test (voir section précédente)
```

### Graphiques n'affichent pas

```bash
# Vérifier les dépendances fl_chart
flutter pub outdated

# Rafraîchir si nécessaire
flutter pub upgrade fl_chart

# Relancer l'app
flutter run
```

### Erreur de compilation Flutter

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run

# Ou avec logs verbeux
flutter run -v
```

## 📈 Tests de Performance

### 1. Temps de chargement

```bash
# Mesurer le temps API
time curl -X GET http://localhost:8080/api/dashboard/enhanced

# Objectif: < 500ms
```

### 2. Mémoire

```bash
# Avec Flutter DevTools
flutter run --dev-tools-server-address localhost:9100

# Vérifier Memory tab
# Objectif: < 100MB pour le dashboard
```

### 3. Responsive

```bash
# Tests sur plusieurs écrans
flutter emulators --launch <emulator_id>

# Ou web
flutter run -d chrome --web-port=3000

# Tester le redimensionnement de fenêtre
```

## ✅ Checklist de Validation

- [ ] Backend compile sans erreurs
- [ ] Frontend compile sans erreurs
- [ ] Connexion à l'API fonctionne
- [ ] Dashboard charge les données
- [ ] Les 4 KPI cards affichent les données correctes
- [ ] Les graphiques s'affichent
- [ ] Les listes de congés affichent les données
- [ ] Les anniversaires s'affichent
- [ ] L'interface est responsive
- [ ] Les couleurs correspondent au design
- [ ] Les shadows sont subtiles
- [ ] Les animations sont lisses
- [ ] Le refresh fonctionne
- [ ] L'app ne crash pas

## 📝 Logs à Vérifier

### Backend
```
[Started GrhMobileApplication]
[No errors in console]
[API requests logged]
```

### Frontend  
```
[✓ Connection to API]
[✓ Data fetched successfully]
[No exceptions in debug console]
```

## 🚀 Déploiement

Une fois tous les tests validés:

```bash
# Backend - Build JAR
cd backend
mvn clean package -DskipTests

# Frontend - Build web
cd ..
flutter build web --release

# Outputs:
# backend/target/grh-mobile-api-1.0.0.jar
# build/web/index.html
```

## 📞 Support

En cas d'erreur:
1. Vérifier les logs (ci-dessus)
2. Nettoyer et reconstruire
3. Vérifier les versions des dépendances
4. Consulter la documentation officielle

---

**Version**: 1.0.0  
**Créé**: 1 mai 2026
