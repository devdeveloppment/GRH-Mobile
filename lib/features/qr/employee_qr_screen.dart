import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/qr_provider.dart';

class EmployeeQrScreen extends ConsumerWidget {
  const EmployeeQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qr = ref.watch(qrNotifierProvider);

    if (qr.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (qr.error != null && qr.qrCode == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(qr.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(qrNotifierProvider).load(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final code = qr.qrCode;
    if (code == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Mon QR Code de présence',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Faites scanner ce code pour enregistrer votre présence',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.text2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── QR Card ────────────────────────────────────────────────────────
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showFullscreen(context, code.qrData),
                    child: QrImageView(
                      data: code.qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    code.nomComplet,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code.matricule,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Actions ────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFullscreen(context, code.qrData),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: const Text('Plein écran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: qr.isRegenerating
                      ? null
                      : () => _confirmRegenerate(context, ref),
                  icon: qr.isRegenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                      qr.isRegenerating ? 'Régénération...' : 'Régénérer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyToken(context, code.token),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier le token'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text2,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Appuyez sur le QR pour l\'agrandir. '
                    'Régénérez-le uniquement si votre QR est compromis.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreen(BuildContext context, String data) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('QR Code',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 300,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRegenerate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Régénérer le QR Code ?'),
        content: const Text(
          'L\'ancien QR Code ne sera plus valide. '
          'Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(qrNotifierProvider).regenerate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
  }

  void _copyToken(BuildContext context, String token) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token copié dans le presse-papier'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
