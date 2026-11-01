// Audit de bout en bout : pour chaque rôle, connexion puis ouverture de chaque
// page de son menu. Signale les erreurs, les redirections inattendues et les
// écrans bloqués sur un chargement. Les états vides sont listés pour revue.
//
// Lancement (émulateur ou appareil Android) :
//   flutter test integration_test/role_pages_audit_test.dart -d emulator-5554
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/routing/app_router.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/main.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

class _Account {
  const _Account(this.label, this.email, this.password, this.role);
  final String label;
  final String email;
  final String password;
  final UserRole role;
}

// Identifiants fournis à l'exécution, jamais écrits dans le code :
//   flutter test integration_test/role_pages_audit_test.dart -d <appareil> //     --dart-define-from-file=integration_test/test_accounts.env
// (voir integration_test/test_accounts.env.example ; le vrai fichier est ignoré par Git)
const _accounts = [
  _Account('ADMIN', String.fromEnvironment('GRH_TEST_ADMIN_EMAIL'),
      String.fromEnvironment('GRH_TEST_ADMIN_PASSWORD'), UserRole.admin),
  _Account('RH_MANAGER', String.fromEnvironment('GRH_TEST_RH_EMAIL'),
      String.fromEnvironment('GRH_TEST_RH_PASSWORD'), UserRole.rhManager),
  _Account('EMPLOYEE', String.fromEnvironment('GRH_TEST_EMPLOYEE_EMAIL'),
      String.fromEnvironment('GRH_TEST_EMPLOYEE_PASSWORD'), UserRole.employee),
  _Account('DIRECTION', String.fromEnvironment('GRH_TEST_DIRECTION_EMAIL'),
      String.fromEnvironment('GRH_TEST_DIRECTION_PASSWORD'), UserRole.direction),
];

/// Mode captures d'écran : --dart-define=GRH_CAPTURES=true
const _captures = bool.fromEnvironment('GRH_CAPTURES');

final _errorWords = RegExp(r'erreur|impossible|échec|echec|exception|inattendu', caseSensitive: false);
final _emptyWords = RegExp(r'aucun|aucune|pas encore|vide', caseSensitive: false);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('fr_TG');
    await dotenv.load(fileName: '.env.example');
    await Hive.initFlutter();
  });

  for (final account in _accounts) {
    testWidgets('Audit des pages — ${account.label}', skip: account.email.isEmpty || account.password.isEmpty,
        (tester) async {
      final problems = <String>[];
      final report = <String>[];

      final errors = <String>[];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const GrhMobileApp(),
      ));
      await _settle(tester);

      // Session restaurée d'un autre compte : on se déconnecte d'abord.
      if (find.text('Se connecter').evaluate().isEmpty) {
        await container.read(authNotifierProvider).logout();
        await _settle(tester);
      }

      // Connexion via le formulaire.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), account.email);
      await tester.enterText(fields.at(1), account.password);
      await tester.tap(find.text('Se connecter'));
      await _settle(tester, seconds: 6);

      if (find.text('Se connecter').evaluate().isNotEmpty) {
        problems.add('CONNEXION échouée pour ${account.email}');
        expect(problems, isEmpty);
        return;
      }
      report.add('CONNEXION OK (${account.email})');

      final router = container.read(appRouterProvider);
      final items = navigationItemsForRole(account.role);
      // Dédoublonnage : certains libellés pointent vers la même route.
      final routes = <String, String>{};
      for (final item in items) {
        routes.putIfAbsent(item.route, () => item.label);
      }

      for (final entry in routes.entries) {
        final route = entry.key;
        final label = entry.value;
        errors.clear();

        router.go(route);
        await _settle(tester, seconds: 4);
        final exception = tester.takeException();
        if (exception != null) {
          errors.add(exception.toString());
          // Diagnostic : arbre de rendu complet dans le log, pour trouver le parent fautif.
          debugPrint('===== DUMP ${account.label} / $label =====');
          debugDumpRenderTree();
        }

        if (_captures) {
          // Repère lu par un script hôte qui prend une capture (adb screencap) de l'écran réel.
          debugPrint('GRH_CAPTURE ${account.label} ${route.replaceAll('/', '_')}');
          await _settle(tester, seconds: 3);
        }
        final location = router.routerDelegate.currentConfiguration.uri.path;
        final texts = _visibleTexts(tester);
        final loading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        final errorTexts = texts.where(_errorWords.hasMatch).toList();
        final emptyTexts = texts.where(_emptyWords.hasMatch).toList();

        final line = '$label [$route] -> $location | textes=${texts.length} '
            'chargement=$loading erreurs=${errors.length} vides=${emptyTexts.length}';
        report.add(line);

        if (location != route) {
          problems.add('${account.label} / $label : redirigé vers $location (accès refusé ?)');
        }
        if (errors.isNotEmpty) {
          problems.add('${account.label} / $label : exception Flutter — ${errors.first}');
        }
        if (errorTexts.isNotEmpty) {
          problems.add('${account.label} / $label : message d\'erreur affiché — ${errorTexts.first}');
        }
        if (loading) {
          problems.add('${account.label} / $label : chargement infini');
        }
        if (emptyTexts.isNotEmpty) {
          report.add('   ↳ état vide : ${emptyTexts.take(2).join(' | ')}');
        }
      }

      // Retour à l'accueil puis déconnexion pour le compte suivant.
      router.go(AppRoutes.login);
      await _settle(tester);
      await container.read(authNotifierProvider).logout();
      await _settle(tester);

      // Rapport lisible dans la console.
      debugPrint('===== RAPPORT ${account.label} =====');
      for (final line in report) {
        debugPrint(line);
      }
      debugPrint('===== PROBLÈMES ${account.label} : ${problems.length} =====');
      for (final p in problems) {
        debugPrint('  - $p');
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }
}

/// Laisse le temps aux requêtes réseau et aux animations de se terminer.
Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

List<String> _visibleTexts(WidgetTester tester) {
  final out = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final value = widget.data ?? widget.textSpan?.toPlainText();
    if (value != null && value.trim().isNotEmpty) out.add(value.trim());
  }
  return out;
}
