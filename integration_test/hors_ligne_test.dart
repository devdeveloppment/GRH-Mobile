// Mode hors ligne sur appareil réel ou émulateur, contre le backend de démonstration :
// coupure (serveur injoignable), saisie d'une demande, bandeau, retour du réseau, synchronisation sans doublon.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/offline/hors_ligne_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/conge_provider.dart';
import 'package:grh_mobile/core/routing/app_router.dart';
import 'package:grh_mobile/main.dart';

const _email = String.fromEnvironment('GRH_TEST_EMPLOYEE_EMAIL');
const _mdp = String.fromEnvironment('GRH_TEST_EMPLOYEE_PASSWORD');
const _captures = bool.fromEnvironment('GRH_CAPTURES');

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('fr_TG');
    await dotenv.load(fileName: '.env.example');
    await Hive.initFlutter();
  });

  testWidgets('Hors ligne : saisie, bandeau, synchronisation au retour du réseau', skip: _email.isEmpty, (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const GrhMobileApp()));
    await _settle(tester);
    if (find.text('Se connecter').evaluate().isEmpty) {
      await container.read(authNotifierProvider).logout();
      await _settle(tester);
    }
    await tester.enterText(find.byType(TextFormField).at(0), _email);
    await tester.enterText(find.byType(TextFormField).at(1), _mdp);
    await tester.tap(find.text('Se connecter'));
    await _settle(tester, seconds: 6);
    if (find.text('Se connecter').evaluate().isNotEmpty) {
      final textes = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().join(' | ');
      debugPrint('ECHEC CONNEXION : ${container.read(authNotifierProvider).errorMessage} // $textes');
    }
    expect(find.text('Se connecter'), findsNothing);
    container.read(appRouterProvider).go(AppRoutes.employeeHome);
    await _settle(tester);

    final api = container.read(apiServiceProvider);
    final file = container.read(fileHorsLigneProvider);
    await file.synchroniser();
    final avant = file.enAttente;

    // Date libre : après toutes les demandes existantes.
    final existants = (await api.get<dynamic>('/conges/me')).data;
    var debut = DateTime.now().add(const Duration(days: 60));
    for (final c in ((existants is Map ? existants['items'] : existants) as List? ?? [])) {
      final fin = DateTime.tryParse(c['dateFin']?.toString() ?? '');
      if (fin != null && !fin.isBefore(debut)) debut = fin.add(const Duration(days: 3));
    }
    final motif = 'Hors ligne ${DateTime.now().millisecondsSinceEpoch}';

    // Coupure : le serveur devient injoignable (même effet qu'une perte de réseau pour l'application).
    final urlReelle = api.client.options.baseUrl;
    api.client.options.baseUrl = 'http://10.255.255.1:9/api';
    api.client.options.connectTimeout = const Duration(seconds: 2);
    final ok = await container.read(congeNotifierProvider).submitRequest(
        typeConge: 'SANS_SOLDE', dateDebut: debut, dateFin: debut.add(const Duration(days: 1)), motif: motif);
    await _settle(tester);
    expect(ok, isTrue);
    expect(file.enAttente, avant + 1);
    expect(find.byKey(const Key('bandeauSynchronisation')), findsOneWidget);
    expect(find.textContaining('en attente'), findsWidgets);
    if (_captures) {
      debugPrint('GRH_CAPTURE horsligne bandeau');
      await _settle(tester, seconds: 3);
    }
    // Tentative pendant la coupure : rien n'est perdu.
    await file.synchroniser();
    expect(file.enAttente, avant + 1);

    // Retour du réseau.
    api.client.options.baseUrl = urlReelle;
    api.client.options.connectTimeout = const Duration(seconds: 15);
    await file.synchroniser();
    await _settle(tester);
    expect(file.enAttente, 0);
    expect(find.byKey(const Key('bandeauSynchronisation')), findsNothing);
    final apres = (await api.get<dynamic>('/conges/me')).data;
    final liste = ((apres is Map ? apres['items'] : apres) as List).where((c) => c['motif'] == motif).toList();
    expect(liste.length, 1, reason: 'une seule demande créée côté serveur');

    await container.read(authNotifierProvider).logout();
    await _settle(tester);
  });
}
