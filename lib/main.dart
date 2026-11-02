
import 'package:flutter/material.dart';
import 'package:grh_mobile/core/offline/bandeau_synchronisation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/routing/app_router.dart';
import 'package:grh_mobile/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_TG');
  // Valeurs par défaut versionnées ; surcharge locale via --dart-define-from-file=.env
  await dotenv.load(fileName: '.env.example');
  await Hive.initFlutter();
  runApp(const ProviderScope(child: GrhMobileApp()));
}

class GrhMobileApp extends ConsumerWidget {
  const GrhMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(authNotifierProvider).registerActivity(),
      child: MaterialApp.router(
        title: 'GRH-Mobile',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        // Bandeau d'état du mode hors ligne, au-dessus de toutes les pages.
        builder: (context, child) => Column(
          children: [
            const BandeauSynchronisation(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
        themeMode: ThemeMode.light,
        locale: const Locale('fr', 'TG'),
        supportedLocales: const [Locale('fr', 'TG'), Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}










