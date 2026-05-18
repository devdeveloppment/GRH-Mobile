import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/widgets/app_form_field.dart';
import 'package:grh_mobile/shared/widgets/grh_logo.dart';

/// Écran public (sans authentification) pour postuler à une offre.
class PostulerScreen extends ConsumerStatefulWidget {
  const PostulerScreen({super.key, required this.offreId, this.offreTitre});

  final String offreId;
  final String? offreTitre;

  @override
  ConsumerState<PostulerScreen> createState() => _PostulerScreenState();
}

class _PostulerScreenState extends ConsumerState<PostulerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;
  bool _submitted = false;

  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _lettre = TextEditingController();

  PlatformFile? _cvFile;
  String? _cvError;

  static const _stepLabels = ['Coordonnées', 'Motivation', 'CV'];

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _telephone, _lettre]) c.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _cvFile = result.files.first;
        _cvError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_cvFile == null) {
      setState(() => _cvError = 'Veuillez joindre votre CV (PDF, DOC ou DOCX).');
      return;
    }
    setState(() { _loading = true; _cvError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final formData = FormData.fromMap({
        'nom': _nom.text.trim(),
        'prenom': _prenom.text.trim(),
        'email': _email.text.trim(),
        'telephone': _telephone.text.trim(),
        'lettreMotivation': _lettre.text.trim(),
        'cv': await MultipartFile.fromFile(
          _cvFile!.path!,
          filename: _cvFile!.name,
        ),
      });
      await api.postFormData<Map<String, dynamic>>(
        '/offres/${widget.offreId}/candidatures/upload',
        formData: formData,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text('Candidature envoyée !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text1)),
            const SizedBox(height: 12),
            Text(
              'Votre dossier a bien été reçu pour le poste "${widget.offreTitre ?? ""}". '
              'Nous vous contacterons à l\'adresse ${_email.text} si votre profil est retenu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // ── En-tête ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GrhLogo(iconSize: 32),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text('Offre ouverte',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.offreTitre ?? 'Postuler',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text1),
              ),
              const SizedBox(height: 4),
              const Text('Complétez le formulaire ci-dessous pour soumettre votre candidature.',
                  style: TextStyle(fontSize: 13, color: AppColors.text2)),
              const SizedBox(height: 20),
              AppStepIndicator(
                currentStep: _step,
                totalSteps: 3,
                labels: _stepLabels,
              ),
            ],
          ),
        ),

        // ── Contenu étape ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(),
              ),
            ),
          ),
        ),

        // ── Navigation ──
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          color: Colors.white,
          child: Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _step--),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: AppColors.text1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _onNext,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_step < 2 ? Icons.arrow_forward_ios_rounded : Icons.send_rounded, size: 16),
                  label: Text(_step < 2 ? 'Continuer' : 'Envoyer ma candidature'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onNext() {
    if (_step < 2) {
      if (_step == 0 && !_formKey.currentState!.validate()) return;
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Form(
          key: _formKey,
          child: AppFormSection(
            title: 'Vos coordonnées',
            subtitle: 'Comment vous contacter ?',
            icon: Icons.person_outline_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppFormField(
                      controller: _prenom,
                      label: 'Prénom *',
                      prefixIcon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFormField(
                      controller: _nom,
                      label: 'Nom *',
                      prefixIcon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _email,
                label: 'Email *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v ?? '').contains('@') ? null : 'Email invalide',
                helperText: 'Vous recevrez une confirmation à cette adresse',
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _telephone,
                label: 'Téléphone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        );

      case 1:
        return AppFormSection(
          title: 'Lettre de motivation',
          subtitle: 'Expliquez pourquoi vous êtes le bon candidat',
          icon: Icons.edit_note_rounded,
          children: [
            AppFormField(
              controller: _lettre,
              label: 'Votre message',
              prefixIcon: Icons.notes_rounded,
              maxLines: 8,
              minLines: 5,
              hint: 'Présentez votre parcours et vos motivations…',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conseil : Mentionnez vos compétences clés, expériences pertinentes et votre disponibilité.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2:
      default:
        return AppFormSection(
          title: 'Votre CV',
          subtitle: 'Formats acceptés : PDF, DOC, DOCX (5 Mo max)',
          icon: Icons.upload_file_rounded,
          children: [
            GestureDetector(
              onTap: _pickCv,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _cvFile != null ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cvFile != null
                        ? Colors.green.shade300
                        : _cvError != null
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: _cvFile == null
                    ? Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Cliquez pour sélectionner votre CV',
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text1)),
                          const SizedBox(height: 4),
                          Text('PDF, DOC, DOCX · 5 Mo max',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.description_outlined,
                                color: Colors.green.shade700, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_cvFile!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, color: AppColors.text1),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(
                                  '${(_cvFile!.size / 1024).toStringAsFixed(1)} Ko',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: () => setState(() => _cvFile = null),
                          ),
                        ],
                      ),
              ),
            ),
            if (_cvError != null) ...[
              const SizedBox(height: 8),
              Text(_cvError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ],
          ],
        );
    }
  }
}
