import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/offline/file_attente_hors_ligne.dart';
import 'package:grh_mobile/core/offline/hors_ligne_provider.dart';
import 'package:grh_mobile/core/constants/app_globals.dart';

/// Bandeau affiché en haut de l'application : hors ligne, opérations en attente, conflits.
/// Invisible quand tout est synchronisé.
class BandeauSynchronisation extends ConsumerWidget {
  const BandeauSynchronisation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(fileHorsLigneProvider);
    if (file.enAttente == 0 && file.conflits == 0) return const SizedBox.shrink();
    final (couleur, icone, texte) = file.conflits > 0
        ? (AppColors.error, Icons.sync_problem, '${file.conflits} opération(s) refusée(s) à vérifier')
        : file.synchronisationEnCours
            ? (AppColors.primary, Icons.sync, 'Synchronisation en cours…')
            : (AppColors.warning, Icons.cloud_off,
                '${file.horsLigne ? 'Hors ligne — ' : ''}${file.enAttente} opération(s) en attente d\'envoi');
    return Material(
      color: couleur,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          key: const Key('bandeauSynchronisation'),
          onTap: () {
            final ctx = rootNavigatorKey.currentContext;
            if (ctx != null) _afficherDetail(ctx);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icone, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(texte, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                const Text('Détails', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _afficherDetail(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (ctx, ref, __) {
        final file = ref.watch(fileHorsLigneProvider);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shrinkWrap: true,
          children: [
            const Text('Opérations saisies hors ligne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text(
              "Elles sont envoyées automatiquement au retour du réseau. Une opération refusée par le serveur "
              "n'est jamais renvoyée sans votre accord.",
              style: TextStyle(fontSize: 12, color: AppColors.text2),
            ),
            const SizedBox(height: 8),
            for (final e in file.elements)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(e.etat == EtatElement.conflit ? Icons.error_outline : Icons.schedule,
                    color: e.etat == EtatElement.conflit ? AppColors.error : AppColors.warning),
                title: Text(e.operation.libelle),
                subtitle: Text(e.etat == EtatElement.conflit
                    ? 'Refusée : ${e.message}'
                    : 'Saisie le ${e.creeLe.day}/${e.creeLe.month} à ${e.creeLe.hour}h${e.creeLe.minute.toString().padLeft(2, '0')}'),
                trailing: Wrap(children: [
                  if (e.etat == EtatElement.conflit)
                    IconButton(tooltip: 'Renvoyer', icon: const Icon(Icons.refresh), onPressed: () => file.reessayer(e.id)),
                  IconButton(tooltip: 'Supprimer', icon: const Icon(Icons.delete_outline), onPressed: () => file.supprimer(e.id)),
                ]),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: file.synchronisationEnCours ? null : file.synchroniser,
              icon: const Icon(Icons.sync),
              label: const Text('Synchroniser maintenant'),
            ),
          ],
        );
      },
    ),
  );
}
