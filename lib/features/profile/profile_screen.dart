import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grh_mobile/core/providers/profile_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileAsync = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        elevation: 1,
      ),
      body: profileAsync.when(
        data: (profile) {
          final user = authState.user;
          final displayName = user != null
              ? '${user.prenom} ${user.nom}'
              : 'Utilisateur';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo de profil
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(context, profileNotifier),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: EmployeeAvatar(
                            name: displayName,
                            imageUrl: profile.photoUrl ?? user?.photoUrl,
                            size: 120,
                          ),
                        ),
                      ),
                      // Bouton pour modifier la photo
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _pickImage(context, profileNotifier),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Nom complet
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nom complet',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'N/A',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Rôle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rôle',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.role.label ?? 'N/A',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton de suppression de photo (si existe)
                if (profile.photoUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: profileNotifier.isSaving
                          ? null
                          : () => _deletePhoto(context, profileNotifier),
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer la photo'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvrir image_picker pour sélectionner une photo
  Future<void> _pickImage(
    BuildContext context,
    ProfileUpdateNotifier profileNotifier,
  ) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) return;

      // Afficher loading
      if (!mounted) return;
      _showLoadingDialog(context);

      // Upload la photo
      final success = await profileNotifier.updatePhoto(pickedFile.path);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Photo uploadée avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Erreur: ${profileNotifier.error}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Supprimer la photo de profil
  Future<void> _deletePhoto(
    BuildContext context,
    ProfileUpdateNotifier profileNotifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer votre photo de profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _showLoadingDialog(context);
    final success = await profileNotifier.deletePhoto();

    if (!mounted) return;
    Navigator.pop(context); // Fermer le loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Photo supprimée'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Erreur: ${profileNotifier.error}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// Afficher un dialog de chargement
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
