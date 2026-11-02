// Parcours d'écriture de bout en bout, contre un backend de DÉMONSTRATION (données fictives) :
// connexion par le formulaire, actions métier par le client HTTP de l'application (mêmes appels que
// les écrans), vérification à l'écran, et refus des actions interdites selon le rôle.
//
//   flutter test integration_test/parcours_ecriture_test.dart -d <appareil> \
//     --dart-define-from-file=integration_test/test_accounts.env
// Web (Chrome) : voir docs/TESTS.md (flutter drive + chromedriver).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/routing/app_router.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/main.dart';

const _admin = (String.fromEnvironment('GRH_TEST_ADMIN_EMAIL'), String.fromEnvironment('GRH_TEST_ADMIN_PASSWORD'));
const _rh = (String.fromEnvironment('GRH_TEST_RH_EMAIL'), String.fromEnvironment('GRH_TEST_RH_PASSWORD'));
const _employe = (String.fromEnvironment('GRH_TEST_EMPLOYEE_EMAIL'), String.fromEnvironment('GRH_TEST_EMPLOYEE_PASSWORD'));
const _direction = (String.fromEnvironment('GRH_TEST_DIRECTION_EMAIL'), String.fromEnvironment('GRH_TEST_DIRECTION_PASSWORD'));
const _plateforme = (String.fromEnvironment('GRH_TEST_PLATFORM_EMAIL'), String.fromEnvironment('GRH_TEST_PLATFORM_PASSWORD'));

/// Mode captures : un repère est écrit dans le journal pour qu'un script hôte capture l'écran.
const _captures = bool.fromEnvironment('GRH_CAPTURES');

late ProviderContainer _container;
ApiService get _api => _container.read(apiServiceProvider);

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _capture(WidgetTester tester, String nom) async {
  if (!_captures) return;
  debugPrint('GRH_CAPTURE parcours $nom');
  await _settle(tester, seconds: 3);
}

Future<void> _connecter(WidgetTester tester, (String, String) compte) async {
  if (find.text('Se connecter').evaluate().isEmpty) {
    await _container.read(authNotifierProvider).logout();
    _container.read(appRouterProvider).go(AppRoutes.login);
    await _settle(tester);
  }
  final champs = find.byType(TextFormField);
  await tester.enterText(champs.at(0), compte.$1);
  await tester.enterText(champs.at(1), compte.$2);
  await tester.tap(find.text('Se connecter'));
  await _settle(tester, seconds: 6);
  if (find.text('Se connecter').evaluate().isNotEmpty) {
    final textes = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().join(' | ');
    debugPrint('ECHEC CONNEXION ${compte.$1} : $textes');
  }
  expect(find.text('Se connecter'), findsNothing, reason: 'connexion de ${compte.$1}');
}

Future<void> _aller(WidgetTester tester, String route) async {
  _container.read(appRouterProvider).go(route);
  await _settle(tester, seconds: 4);
  expect(tester.takeException(), isNull, reason: 'exception sur $route');
}

Future<void> _defilerJusqua(WidgetTester tester, Finder cible) async {
  if (cible.evaluate().isEmpty) {
    await tester.scrollUntilVisible(cible, 250, scrollable: find.byType(Scrollable).last, maxScrolls: 200);
    await _settle(tester, seconds: 1);
  }
}

Future<void> _fermerDetail(WidgetTester tester) async {
  Navigator.of(tester.element(find.byKey(const Key('detailProcessus')))).pop();
  await _settle(tester);
}

String _route() => _container.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

/// Code HTTP d'un appel (200, 403…), sans lever d'exception.
Future<int> _statut(Future<Response<dynamic>> Function() appel) async {
  try {
    return (await appel()).statusCode ?? 0;
  } on DioException catch (e) {
    return e.response?.statusCode ?? -1;
  }
}

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final suffixe = DateTime.now().millisecondsSinceEpoch.toString().substring(7);

  setUpAll(() async {
    await initializeDateFormatting('fr_TG');
    await dotenv.load(fileName: '.env.example');
    await Hive.initFlutter();
  });

  testWidgets('Parcours d\'écriture — 4 rôles + plateforme', skip: _admin.$1.isEmpty, (tester) async {
    _container = ProviderContainer();
    addTearDown(_container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const GrhMobileApp()));
    await _settle(tester);

    // ── RH : création et modification d'un employé ──────────────────────────
    await _connecter(tester, _rh);
    final services = (await _api.get<Map<String, dynamic>>('/services')).data;
    final service = ((services?['items'] ?? services?['content']) as List).first['nom'] as String;
    final nom = 'Fictif$suffixe';
    final cree = await _api.post<Map<String, dynamic>>('/employees', data: {
      'nom': nom,
      'prenom': 'Testeur',
      'email': 'testeur.$suffixe@exemple.test',
      'poste': 'Agent de test',
      'service': service,
      'typeContrat': 'CDD',
      'salaire': 150000,
      'dateEmbauche': _date(DateTime.now()),
      'dateFin': _date(DateTime.now().add(const Duration(days: 180))),
    });
    expect(cree.statusCode, 201);
    final matricule = (cree.data?['employe'] ?? cree.data)?['matricule'] as String;
    final modif = await _api.put<Map<String, dynamic>>('/employees/$matricule', data: {
      'nom': nom,
      'prenom': 'Testeur',
      'email': 'testeur.$suffixe@exemple.test',
      'poste': 'Agent de test confirmé',
      'service': service,
      'typeContrat': 'CDD',
      'salaire': 160000,
    });
    expect(modif.statusCode, 200);
    await _aller(tester, AppRoutes.employees);
    await _capture(tester, 'rh_employes');

    // ── RH : arrivée de l'employé, depuis l'écran ───────────────────────────
    await _api.post<Map<String, dynamic>>('/employees/$matricule/integration/arrivee',
        data: {'echeance': _date(DateTime.now().add(const Duration(days: 7)))});
    await _aller(tester, AppRoutes.integration);
    await _defilerJusqua(tester, find.textContaining(nom));
    expect(find.textContaining(nom), findsWidgets, reason: 'processus visible dans la liste');
    await _capture(tester, 'rh_integration_liste');
    await tester.tap(find.textContaining(nom).first);
    await _settle(tester, seconds: 4);
    await _capture(tester, 'rh_integration_detail');
    // Coche la première tâche dans l'interface.
    await tester.tap(find.byType(Checkbox).first);
    await _settle(tester, seconds: 4);
    final suivi = (await _api.get<Map<String, dynamic>>('/employees/$matricule/integration')).data!;
    expect(suivi['faites'], 1);
    // Fin de l'arrivée : toutes les tâches, puis clôture depuis l'écran.
    for (final t in (suivi['items'] as List).where((t) => t['faite'] != true)) {
      await _api.put<Map<String, dynamic>>('/integration/taches/${t['id']}', data: {'faite': true});
    }
    await _fermerDetail(tester);
    await _defilerJusqua(tester, find.textContaining(nom));
    await tester.tap(find.textContaining(nom).first);
    await _settle(tester, seconds: 4);
    await tester.tap(find.byKey(const Key('cloturerProcessus')));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Clôturer'));
    await _settle(tester, seconds: 4);
    final clos = (await _api.get<Map<String, dynamic>>('/employees/$matricule/integration')).data!;
    expect((clos['clotures'] as Map)['ARRIVEE'], isNotNull, reason: 'clôture enregistrée');
    await _fermerDetail(tester);

    // Départ : liste générée puis clôture refusée tant que des tâches restent.
    await _api.post<Map<String, dynamic>>('/employees/$matricule/integration/depart', data: {});
    expect(await _statut(() => _api.post('/employees/$matricule/integration/depart/cloture')), 400);

    // ── Employé : demande de congé, note de frais, consultations ────────────
    await _connecter(tester, _employe);
    // Après toutes les demandes existantes (une demande ne peut pas en chevaucher une autre).
    final existants = (await _api.get<dynamic>('/conges/me')).data;
    var debut = DateTime.now().add(const Duration(days: 30));
    for (final c in ((existants is Map ? existants['items'] : existants) as List? ?? [])) {
      final fin = DateTime.tryParse(c['dateFin']?.toString() ?? '');
      if (fin != null && !fin.isBefore(debut)) debut = fin.add(const Duration(days: 3));
    }
    final c1 = await _api.post<Map<String, dynamic>>('/conges', data: {
      'typeConge': 'SANS_SOLDE', 'dateDebut': _date(debut), 'dateFin': _date(debut.add(const Duration(days: 1))),
      'motif': 'Parcours de test',
    });
    final c2 = await _api.post<Map<String, dynamic>>('/conges', data: {
      'typeConge': 'SANS_SOLDE', 'dateDebut': _date(debut.add(const Duration(days: 10))),
      'dateFin': _date(debut.add(const Duration(days: 11))), 'motif': 'Parcours de test (refus)',
    });
    expect([c1.statusCode, c2.statusCode], [201, 201]);
    final frais = <int>[];
    for (final montant in [12500, 4800]) {
      final r = await _api.postFormData<Map<String, dynamic>>('/notes-frais', formData: FormData.fromMap({
        'dateDepense': _date(DateTime.now()), 'categorie': 'TRANSPORT', 'montant': montant,
        'description': 'Taxi fictif $suffixe',
      }));
      expect(r.statusCode, 201);
      frais.add((r.data!['id'] as num).toInt());
    }
    // Actions interdites à l'employé.
    expect(await _statut(() => _api.post('/conges/${c1.data!['id']}/approve')), 403);
    expect(await _statut(() => _api.post('/notes-frais/${frais.first}/approve')), 403);
    expect(await _statut(() => _api.get('/paie/rubriques')), 403);
    expect(await _statut(() => _api.get('/integration/processus')), 403);
    expect(await _statut(() => _api.get('/plateforme/entreprises')), 403);
    // Consultations : documents, évaluations, bulletins.
    for (final url in ['/employees/me/documents', '/employees/me/evaluations', '/conges/me', '/notes-frais/me']) {
      expect(await _statut(() => _api.get(url)), 200, reason: url);
    }
    await _aller(tester, AppRoutes.employeeHome);
    await _capture(tester, 'employe_accueil');
    await _aller(tester, AppRoutes.notesFrais);
    expect(find.textContaining('Taxi fictif $suffixe'), findsWidgets);
    await _capture(tester, 'employe_notes_frais');
    // L'employé n'accède pas aux écrans RH.
    await _aller(tester, AppRoutes.paieConfiguration);
    expect(_route(), isNot(AppRoutes.paieConfiguration));

    // ── RH : décisions ──────────────────────────────────────────────────────
    await _connecter(tester, _rh);
    expect(await _statut(() => _api.post('/conges/${c1.data!['id']}/approve', data: {'commentaire': 'OK'})), anyOf(200, 204));
    expect(await _statut(() => _api.post('/conges/${c2.data!['id']}/reject', data: {'commentaire': 'Refus test'})),
        anyOf(200, 204));
    expect(await _statut(() => _api.post('/notes-frais/${frais[0]}/approve')), 200);
    expect(await _statut(() => _api.post('/notes-frais/${frais[1]}/reject', data: {'commentaire': 'Justificatif manquant'})),
        200);
    await _aller(tester, AppRoutes.conges);
    await _capture(tester, 'rh_conges');

    // ── Employé : vérifie les décisions ─────────────────────────────────────
    await _connecter(tester, _employe);
    final mesConges = (await _api.get<dynamic>('/conges/me')).data;
    final liste = (mesConges is Map ? mesConges['items'] : mesConges) as List;
    String statutDe(Object? id) => liste.firstWhere((c) => c['id'] == id)['statut'] as String;
    expect(statutDe(c1.data!['id']), 'APPROUVE');
    expect(statutDe(c2.data!['id']), 'REFUSE');
    final mesFrais = ((await _api.get<Map<String, dynamic>>('/notes-frais/me')).data!['items'] as List);
    expect(mesFrais.firstWhere((n) => n['id'] == frais[0])['statut'], 'APPROUVEE');
    expect(mesFrais.firstWhere((n) => n['id'] == frais[1])['statut'], 'REFUSEE');

    // ── Direction : lecture seule ───────────────────────────────────────────
    await _connecter(tester, _direction);
    expect(await _statut(() => _api.get('/evaluations')), 200);
    expect(await _statut(() => _api.post('/employees', data: {
          'nom': 'Interdit', 'prenom': 'Direction', 'email': 'interdit.$suffixe@exemple.test', 'poste': 'X',
          'service': service, 'typeContrat': 'CDI', 'salaire': 1})), 403);
    expect(await _statut(() => _api.post('/conges/${c2.data!['id']}/approve')), 403);
    await _aller(tester, AppRoutes.evaluations);
    await _capture(tester, 'direction_evaluations');

    // ── Admin : configuration de la paie (circuit de validation) ────────────
    await _connecter(tester, _admin);
    final code = 'TEST_FICTIF_$suffixe';
    final p = await _api.post<Map<String, dynamic>>('/paie/parametres', data: {
      'code': code, 'libelle': 'Paramètre fictif de démonstration', 'valeur': '0.01', 'dateDebut': '2026-01-01',
    });
    expect(p.data!['statut'], 'BROUILLON');
    await _aller(tester, AppRoutes.paieConfiguration);
    expect(find.textContaining('Brouillon'), findsWidgets);
    await _capture(tester, 'admin_paie_configuration');
    expect(await _statut(() => _api.put('/paie/parametres/${p.data!['id']}/soumission',
        data: {'source': 'Source fictive (démonstration)'})), 200);
    // La personne qui soumet ne peut pas valider.
    expect(await _statut(() => _api.put('/paie/parametres/${p.data!['id']}/validation', data: {
          'validePar': 'X', 'qualiteValidateur': 'EXPERT_COMPTABLE', 'source': 'Source fictive'})), 400);
    // Un administrateur d'entreprise n'accède pas à la plateforme.
    expect(await _statut(() => _api.get('/plateforme/entreprises')), 403);
    await _aller(tester, AppRoutes.plateforme);
    expect(_route(), isNot(AppRoutes.plateforme));

    // ── Super-administrateur : administration des entreprises ──────────────
    if (_plateforme.$1.isNotEmpty) {
      await _connecter(tester, _plateforme);
      await _aller(tester, AppRoutes.plateforme);
      expect(_route(), AppRoutes.plateforme);
      expect(find.textContaining('demo-b'), findsWidgets);
      await _capture(tester, 'plateforme_liste');
      final slug = 'test-$suffixe';
      final e = await _api.post<Map<String, dynamic>>('/plateforme/entreprises', data: {
        'nom': 'Entreprise fictive $suffixe', 'slug': slug, 'offre': 'ESSAI', 'adminEmail': 'admin@$slug.example',
      });
      final id = (e.data!['id'] as num).toInt();
      expect(await _statut(() => _api.put('/plateforme/entreprises/$id/statut', data: {'statut': 'SUSPENDUE'})), 200);
      expect(await _statut(() => _api.put('/plateforme/entreprises/$id/offre', data: {'offre': 'PRO'})), 200);
      await _aller(tester, AppRoutes.notifications); // quitte la page pour recharger la liste
      await _aller(tester, AppRoutes.plateforme);
      await _defilerJusqua(tester, find.textContaining('Entreprise fictive $suffixe'));
      await tester.tap(find.textContaining('Entreprise fictive $suffixe'));
      await _settle(tester, seconds: 4);
      expect(find.text('Suspendue'), findsWidgets);
      await _capture(tester, 'plateforme_fiche');
      // Réactivation depuis l'écran.
      await tester.tap(find.text('Réactiver'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
      await _settle(tester, seconds: 4);
      final d = (await _api.get<Map<String, dynamic>>('/plateforme/entreprises/$id')).data!;
      expect(d['statut'], 'ACTIVE');
    }

    await _container.read(authNotifierProvider).logout();
    await _settle(tester);
  });
}
