import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/utils/validators.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';
import 'package:grh_mobile/shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _idCtrl    = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  bool _obscure    = true;

  static const _breakpoint = 900.0;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = ref.read(authNotifierProvider);
    final success = await auth.login(
      email:    _idCtrl.text.trim(),
      password: _pwdCtrl.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            auth.errorMessage ?? 'Identifiants invalides.',
          ),
        ));
      return;
    }

    final role = ref.read(authNotifierProvider).role;
    if (role != null) context.go(defaultRouteForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= _breakpoint;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: isWide ? _WebLayout(form: _form()) : _MobileLayout(form: _form()),
      ),
    );
  }

  // ── Form shared between layouts ──────────────────────────────────────────────
  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Identifiant ────────────────────────────────────────────────────
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'E-mail ou matricule',
              hintText:  'ex: EMP001 ou jean@entreprise.com',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Identifiant requis.' : null,
          ),
          const SizedBox(height: 16),

          // ── Mot de passe ───────────────────────────────────────────────────
          TextFormField(
            controller:     _pwdCtrl,
            obscureText:    _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText:  'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: FormValidators.validateRequired,
          ),
          const SizedBox(height: 10),

          // ── Mot de passe oublié ────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Bouton Se connecter ────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Se connecter'),
            ),
          ),
          const SizedBox(height: 20),

          // ── Mention bas ───────────────────────────────────────────────────
          const Text(
            "Pas encore de compte ? Contactez votre RH",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout : 40% vert (logo) + 60% blanc (form) ──────────────────────
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zone verte — 40%
        Expanded(
          flex: 4,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GrhLogo(iconSize: 52, textScale: 1.0, darkBackground: true),
                  const SizedBox(height: 10),
                  const Text(
                    'Votre gestion RH simplifiée',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Zone blanche — 60%
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft:  Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connectez-vous à votre espace GRH-MOBILE.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  form,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Web layout : panneau vert gauche + formulaire blanc droit ────────────────
class _WebLayout extends StatelessWidget {
  const _WebLayout({required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panneau gauche — vert #0E3D34
        Expanded(
          flex: 11,
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const GrhLogo(iconSize: 48, textScale: 0.95, darkBackground: true),
                const Spacer(),
                const Text(
                  'Une expérience RH\npremium, pensée pour\nle web et le mobile.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Centralisez employés, documents, compétences,\ncongés, paie et analytics dans une interface sobre.',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeaturePill(icon: Icons.folder_copy_outlined,      label: 'Documents centralisés'),
                    _FeaturePill(icon: Icons.psychology_alt_outlined,    label: 'Compétences suivies'),
                    _FeaturePill(icon: Icons.auto_graph_outlined,        label: 'Analytics RH'),
                    _FeaturePill(icon: Icons.notifications_active_outlined, label: 'Alertes intelligentes'),
                  ],
                ),
                const Spacer(),
                Row(
                  children: const [
                    Expanded(child: _Metric(label: 'Employés suivis',   value: '128')),
                    SizedBox(width: 12),
                    Expanded(child: _Metric(label: 'Taux de présence',  value: '96%')),
                    SizedBox(width: 12),
                    Expanded(child: _Metric(label: 'Demandes traitées', value: '18')),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Panneau droit — blanc
        Expanded(
          flex: 9,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connectez-vous avec votre e-mail ou matricule.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      form,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pills décoratifs panneau gauche ──────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Métriques panneau gauche ──────────────────────────────────────────────────
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xCCFFFFFF), fontSize: 12)),
        ],
      ),
    );
  }
}
