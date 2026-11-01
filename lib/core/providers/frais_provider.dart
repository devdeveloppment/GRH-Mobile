import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';

/// Notes de frais de l'employé connecté.
final mesNotesFraisProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/notes-frais/me');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

/// Toutes les notes (RH / paie), filtrées par statut si fourni.
final toutesNotesFraisProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>((ref, statut) async {
  final api = ref.read(apiServiceProvider);
  final query = statut != null ? '?statut=$statut' : '';
  final resp = await api.get<Map<String, dynamic>>('/notes-frais$query');
  final raw = resp.data?['items'] as List? ?? [];
  return raw.whereType<Map<String, dynamic>>().toList();
});

const categoriesFrais = <String, String>{
  'TRANSPORT': 'Transport',
  'REPAS': 'Repas',
  'HEBERGEMENT': 'Hébergement',
  'FOURNITURES': 'Fournitures',
  'COMMUNICATION': 'Communication',
  'AUTRE': 'Autre',
};

const statutsFrais = <String, String>{
  'SOUMISE': 'Soumise',
  'APPROUVEE': 'Approuvée',
  'REFUSEE': 'Refusée',
  'REMBOURSEE': 'Remboursée',
};
