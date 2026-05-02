# 🏗️ Architecture & Guide Développeur - Dashboard RH

## 📐 Architecture Générale

```
┌─────────────────────────────────────────────┐
│           UI Layer (Flutter)                │
│  ┌──────────────────────────────────────┐   │
│  │   RhDashboardModernScreen            │   │
│  │  (rh_dashboard_modern.dart)          │   │
│  └──────────────────────────────────────┘   │
│           ↓ Uses                             │
│  ┌──────────────────────────────────────┐   │
│  │   Widgets Layer                      │   │
│  │  • DashboardKPICard                  │   │
│  │  • AttendanceLineChart               │   │
│  │  • DepartmentDonutChart              │   │
│  │  • LeaveRequestCard                  │   │
│  │  • BirthdayCard                      │   │
│  │  • QuickActionButton                 │   │
│  └──────────────────────────────────────┘   │
│           ↓ Uses                             │
│  ┌──────────────────────────────────────┐   │
│  │   State Management (Riverpod)        │   │
│  │  • enhancedDashboardProvider         │   │
│  │  • authNotifierProvider              │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
            ↓ HTTP Requests
┌─────────────────────────────────────────────┐
│      Network Layer (API Service)            │
│  • apiServiceProvider                       │
│  • JSON serialization/deserialization       │
└─────────────────────────────────────────────┘
            ↓ REST API
┌─────────────────────────────────────────────┐
│       API Layer (Spring Boot)               │
│  GET /api/dashboard/enhanced                │
└─────────────────────────────────────────────┘
            ↓ Service Layer
┌─────────────────────────────────────────────┐
│    Business Logic (DashboardService)        │
│  • getEnhancedDashboard()                   │
│  • buildRecentLeaveRequests()               │
│  • buildUpcomingBirthdays()                 │
│  • buildQuickStats()                        │
│  • buildAttendanceEvolution()               │
│  • buildDepartmentBreakdown()               │
│  • buildPayrollBreakdown()                  │
└─────────────────────────────────────────────┘
            ↓ Repository Layer
┌─────────────────────────────────────────────┐
│    Data Access Layer                        │
│  • EmployeRepository                        │
│  • PresenceRepository                       │
│  • CongeRepository                          │
│  • FichePaieRepository                      │
└─────────────────────────────────────────────┘
            ↓ SQL
┌─────────────────────────────────────────────┐
│         Database (PostgreSQL)               │
│  Tables: employes, presences, conges, etc   │
└─────────────────────────────────────────────┘
```

## 📦 Structure des Fichiers

```
grh_mobile/
├── lib/
│   ├── core/
│   │   ├── providers/
│   │   │   └── dashboard_provider.dart         # ⭐ Provider Riverpod
│   │   └── routing/
│   │       └── app_router.dart                 # Routes
│   ├── shared/
│   │   ├── models/
│   │   │   └── dashboard_models.dart           # ⭐ 5 Modèles
│   │   └── widgets/
│   │       ├── dashboard_kpi_card.dart         # ⭐ Widget KPI
│   │       ├── attendance_line_chart.dart      # ⭐ Widget Courbe
│   │       ├── department_donut_chart.dart     # ⭐ Widget Donut
│   │       ├── leave_request_card.dart         # ⭐ Widget Congé
│   │       ├── birthday_card.dart              # ⭐ Widget Anniversaire
│   │       └── quick_action_button.dart        # ⭐ Widget Action
│   └── features/
│       └── dashboard/
│           └── rh_dashboard_modern.dart        # ⭐ Écran principal
│
├── backend/
│   └── src/main/java/com/grhmobile/
│       ├── dto/dashboard/
│       │   ├── LeaveRequestDto.java            # ⭐ Nouveau DTO
│       │   ├── BirthdayDto.java                # ⭐ Nouveau DTO
│       │   ├── QuickStatsDto.java              # ⭐ Nouveau DTO
│       │   └── EnhancedDashboardResponse.java  # ⭐ Nouveau DTO
│       ├── service/
│       │   └── DashboardService.java           # ⭐ Enrichi
│       ├── controller/
│       │   └── DashboardController.java        # ⭐ Enrichi
│       └── enums/
│           └── TypeContrat.java                # ⭐ Enrichi (ajout STAGE)
```

## 🔄 Flux de Données Détaillé

### Frontend -> Backend
```dart
// 1. FutureProvider déclenche une requête
final enhancedDashboardProvider = FutureProvider.autoDispose<EnhancedDashboard>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get<Map<String, dynamic>>('/dashboard/enhanced');
  return EnhancedDashboard.fromJson(response.data ?? {});
});

// 2. Widget l'utilise
dashboardAsync.when(
  data: (dashboard) => _buildDashboardContent(context, dashboard, isWide),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(),
)
```

### Backend -> Base de Données
```java
// 1. Controller reçoit la requête
@GetMapping("/enhanced")
public EnhancedDashboardResponse enhanced() {
  return dashboardService.getEnhancedDashboard();
}

// 2. Service récupère les données
@Transactional(readOnly = true)
public EnhancedDashboardResponse getEnhancedDashboard() {
  List<Employe> employees = employeRepository.findAll();
  List<Conge> leaves = congeRepository.findAll();
  // ... construit les objets DTO
  return new EnhancedDashboardResponse(...);
}

// 3. Repositories interrogent la BD
employees.stream()
  .filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut()))
  .count();
```

## 🎯 Points d'Extension

### Pour Ajouter une Nouvelle Carte KPI

1. **Backend** - Ajouter la propriété à `EnhancedDashboardResponse`
```java
public record EnhancedDashboardResponse(
    ...
    long myNewMetric,  // ← Nouvelle métrique
    ...
)
```

2. **Backend** - Calculer la valeur dans `DashboardService`
```java
long myMetric = calculateMyMetric(employees);
```

3. **Frontend** - Ajouter le modèle à `EnhancedDashboard`
```dart
class EnhancedDashboard {
  final int myNewMetric;  // ← Nouvelle propriété
}
```

4. **Frontend** - Afficher la carte dans `RhDashboardModernScreen`
```dart
DashboardKPICard(
  icon: Icons.my_icon,
  title: 'Mon Titre',
  value: '${dashboard.myNewMetric}',
  subtitle: 'Subtitile',
),
```

### Pour Ajouter un Nouveau Graphique

1. **Créer un widget personnalisé**
```dart
// lib/shared/widgets/my_chart.dart
class MyChart extends StatelessWidget {
  final List<ChartPoint> data;
  
  const MyChart({required this.data});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // ... votre implémentation
    );
  }
}
```

2. **L'utiliser dans le dashboard**
```dart
MyChart(data: dashboard.myChartData)
```

### Pour Ajouter une Nouvelle Listes

1. **Ajouter le DTO backend**
```java
public record MyItemDto(
  Long id,
  String name,
  String status
) {}
```

2. **Ajouter à EnhancedDashboardResponse**
```java
List<MyItemDto> myItems
```

3. **Calculer dans DashboardService**
```java
private List<MyItemDto> buildMyItems(...) {
  return entities.stream()
    .map(e -> new MyItemDto(...))
    .toList();
}
```

4. **Créer un widget pour afficher**
```dart
class MyItemCard extends StatelessWidget {
  final MyItem item;
  
  @override
  Widget build(BuildContext context) {
    // ... affichage
  }
}
```

5. **L'utiliser dans le dashboard**
```dart
ListView.builder(
  itemCount: dashboard.myItems.length,
  itemBuilder: (context, index) => MyItemCard(
    item: dashboard.myItems[index],
  ),
)
```

## 🎨 Réutilisation des Widgets

### DashboardKPICard
```dart
DashboardKPICard(
  icon: Icons.people,
  iconColor: Colors.blue,
  title: 'Titre',
  value: '123',
  subtitle: 'Sous-titre',
)
```

### QuickActionButton
```dart
QuickActionButton(
  icon: Icons.add,
  label: 'Ajouter',
  onTap: () { /* action */ },
)
```

### LeaveRequestCard
```dart
LeaveRequestCard(leave: leaveObject)
```

### BirthdayCard
```dart
BirthdayCard(birthday: birthdayObject)
```

### AttendanceLineChart
```dart
AttendanceLineChart(
  data: chartPoints,
  title: 'Évolution des présences',
)
```

### DepartmentDonutChart
```dart
DepartmentDonutChart(
  data: departmentPoints,
  title: 'Répartition',
)
```

## 🧪 Tester une Nouvelle Fonctionnalité

```bash
# 1. Créer/modifier le DTO backend
# 2. Compiler le backend
mvn clean compile

# 3. Créer/modifier le modèle Flutter
# 4. Générer le code si nécessaire
dart run build_runner build

# 5. Compiler Flutter
flutter pub get

# 6. Lancer l'app
flutter run -d web --web-port=3000

# 7. Vérifier dans les logs
# Backend: POST /api/dashboard/enhanced 200 OK
# Frontend: ✓ Data loaded successfully
```

## 🚨 Gestion d'Erreur

### Backend - Erreur dans le calcul
```java
try {
  // calcul
} catch (Exception e) {
  log.error("Erreur calcul dashboard", e);
  // Retourner valeur par défaut ou lancer exception
  throw new DashboardException("Erreur: " + e.getMessage());
}
```

### Frontend - Erreur réseau
```dart
enhancedDashboardProvider.when(
  error: (error, stack) {
    print('Erreur: $error');
    return Center(
      child: Column(
        children: [
          Text('Erreur: $error'),
          ElevatedButton(
            onPressed: () => ref.refresh(enhancedDashboardProvider),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  },
)
```

## 📊 Performance Optimization

### Caching Backend
```java
// Ajouter Redis cache
@Cacheable(value = "dashboard", unless = "#result == null")
public EnhancedDashboardResponse getEnhancedDashboard() {
  // ...
}

// Invalider le cache
@CacheEvict(value = "dashboard", allEntries = true)
public void invalidateCache() {}
```

### Pagination
```java
// Pour les listes longues
public Page<LeaveRequest> getRecentLeaves(Pageable pageable) {
  return congeRepository.findRecent(pageable);
}
```

### Lazy Loading
```dart
// Charger les données au besoin
Future<EnhancedDashboard> loadDashboard() async {
  // Charger en parallèle
  final [kpis, charts, lists] = await Future.wait([
    fetchKPIs(),
    fetchCharts(),
    fetchLists(),
  ]);
}
```

## 🔐 Sécurité

- ✅ Token JWT pour l'authentification
- ✅ @Transactional(readOnly = true) pour les GET
- ✅ Validation des données côté backend
- ✅ Sanitization des inputs
- ✅ CORS configuré correctement

## 📈 Monitoring

```bash
# Métriques Actuator (Spring Boot)
GET http://localhost:8080/actuator/metrics

# Logs
tail -f backend/logs/app.log

# Debugging Flutter
flutter logs
```

---

**Version**: 1.0.0  
**Créé**: 1 mai 2026  
**Dernière mise à jour**: 1 mai 2026
