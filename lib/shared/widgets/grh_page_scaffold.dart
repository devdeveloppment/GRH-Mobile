import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/grh_app_bar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';

/// Structure commune des pages : barre latérale (large écran) ou tiroir (mobile), en-tête et contenu.
class GrhPageScaffold extends ConsumerWidget {
  const GrhPageScaffold({
    super.key,
    required this.title,
    required this.route,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final String route;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: floatingActionButton,
      drawer: isWide || auth.role == null
          ? null
          : Drawer(child: GrhSidebar(currentRoute: route, role: auth.role!, isDrawer: true)),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Builder(
          builder: (ctx) => GrhAppBar(
            title: title,
            userName: auth.user?.fullName,
            onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Row(
        children: [
          if (isWide && auth.role != null) GrhSidebar(currentRoute: route, role: auth.role!),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Badge de statut coloré (succès, attention, danger, neutre).
class GrhBadge extends StatelessWidget {
  const GrhBadge(this.label, {super.key, this.tone = GrhBadgeTone.neutral});

  final String label;
  final GrhBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      GrhBadgeTone.success => (AppColors.badgeSuccessBg, AppColors.badgeSuccessFg),
      GrhBadgeTone.warning => (AppColors.badgeWarnBg, AppColors.badgeWarnFg),
      GrhBadgeTone.danger => (AppColors.badgeDangerBg, AppColors.badgeDangerFg),
      GrhBadgeTone.neutral => (AppColors.surface, AppColors.text2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

enum GrhBadgeTone { success, warning, danger, neutral }

/// Bandeau d'information ou d'avertissement.
class GrhBanner extends StatelessWidget {
  const GrhBanner(this.message, {super.key, this.icon = Icons.info_outline});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Message d'erreur lisible à partir d'une réponse de l'API.
String messageErreur(Object error, [String defaut = 'Opération impossible.']) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (error.response?.statusCode == 403) return "Vous n'avez pas les droits nécessaires.";
  }
  return defaut;
}

void grhSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : null),
  );
}

/// Contenu d'un FutureProvider : chargement, erreur avec bouton « Réessayer », ou données.
class GrhAsync<T> extends StatelessWidget {
  const GrhAsync({super.key, required this.value, required this.data, required this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(messageErreur(e, 'Chargement impossible.'), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

String formatDate(String? iso) {
  if (iso == null || iso.length < 10) return '—';
  final p = iso.substring(0, 10).split('-');
  return '${p[2]}/${p[1]}/${p[0]}';
}

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
