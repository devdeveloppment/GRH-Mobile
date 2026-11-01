import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

/// Affiche une seule fois le mot de passe temporaire d'un compte nouvellement créé.
/// L'utilisateur devra le changer à sa première connexion.
Future<void> showTemporaryPasswordDialog(
  BuildContext context, {
  required String email,
  required String password,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Compte créé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Communiquez ces identifiants à la personne par un canal sûr. '
            'Le mot de passe ne sera plus affiché et devra être changé à la première connexion.',
            style: TextStyle(fontSize: 13, color: AppColors.text2),
          ),
          const SizedBox(height: 16),
          SelectableText('Identifiant : $email', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  'Mot de passe : $password',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Copier',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Mot de passe copié.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("J'ai noté le mot de passe"),
        ),
      ],
    ),
  );
}
