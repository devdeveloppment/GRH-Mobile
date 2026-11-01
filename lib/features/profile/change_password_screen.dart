import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';

/// Changement de mot de passe, disponible pour tous les rôles.
/// Obligatoire tant que l'utilisateur utilise un mot de passe temporaire.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Au moins 8 caractères.';
    if (!RegExp('[A-Z]').hasMatch(v)) return 'Au moins une majuscule.';
    if (!RegExp('[a-z]').hasMatch(v)) return 'Au moins une minuscule.';
    if (!RegExp('[0-9]').hasMatch(v)) return 'Au moins un chiffre.';
    if (v == _currentCtrl.text) return "Doit être différent de l'actuel.";
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiServiceProvider).put<Map<String, dynamic>>(
        '/profile/password',
        data: {
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        },
      );
      final auth = ref.read(authNotifierProvider);
      await auth.markPasswordChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifié avec succès.')),
      );
      final role = auth.role;
      if (role != null) context.go(defaultRouteForRole(role));
    } catch (e) {
      setState(() => _error = ApiService.messageOf(e, 'Mot de passe actuel incorrect ou erreur serveur.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final forced = auth.mustChangePassword;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Changer mon mot de passe'),
        automaticallyImplyLeading: !forced,
        actions: [
          if (forced)
            TextButton(
              onPressed: () => ref.read(authNotifierProvider).logout(),
              child: const Text('Se déconnecter'),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (forced)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.badgeWarnBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Pour sécuriser votre compte, remplacez le mot de passe '
                            'temporaire qui vous a été communiqué avant de continuer.',
                            style: TextStyle(color: AppColors.badgeWarnFg),
                          ),
                        ),
                      TextFormField(
                        controller: _currentCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          helperText: '8 caractères min., majuscule, minuscule et chiffre',
                        ),
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
                        validator: (v) => v != _newCtrl.text ? 'Les mots de passe ne correspondent pas.' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: !_obscure,
                        onChanged: (v) => setState(() => _obscure = !(v ?? false)),
                        title: const Text('Afficher les mots de passe'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                        ),
                      ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
