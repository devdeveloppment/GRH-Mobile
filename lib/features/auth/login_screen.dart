import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/constants/app_strings.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/widgets/african_pattern.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';
import 'package:grh_mobile/shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final auth = ref.read(authNotifierProvider);
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Mauvais identifiants ou compte indisponible.'),
          ),
        );
      return;
    }

    final role = ref.read(authNotifierProvider).role;
    if (role != null) {
      context.go(defaultRouteForRole(role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final size = MediaQuery.sizeOf(context);
    final cardWidth = size.width > 1080 ? 460.0 : 420.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.authGradient),
        child: AfricanPattern(
          opacity: 0.06,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LoadingOverlay(
                  isLoading: auth.isLoading,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            const Center(
                              child: GrhLogo(
                                iconSize: 58,
                                textScale: 1.05,
                                stacked: true,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              AppStrings.loginTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Authentification sécurisée par JWT pour votre plateforme RH web et mobile.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                                  ),
                            ),
                            const SizedBox(height: 28),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.email,
                                      prefixIcon: Icon(Icons.mail_outline_rounded),
                                    ),
                                    validator: (value) {
                                      final input = value?.trim() ?? '';
                                      if (input.isEmpty) {
                                        return 'Veuillez renseigner votre e-mail.';
                                      }
                                      final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
                                      if (!isValid) {
                                        return 'Adresse e-mail invalide.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscureText,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.password,
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(() => _obscureText = !_obscureText),
                                        icon: Icon(
                                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Veuillez renseigner votre mot de passe.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (auth.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      auth.errorMessage!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: auth.isLoading ? null : _submit,
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('SE CONNECTER'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
