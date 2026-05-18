import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';

final serviceNotifierProvider =
    ChangeNotifierProvider.autoDispose<ServiceNotifier>((ref) {
  final notifier = ServiceNotifier(ref.read(apiServiceProvider));
  unawaited(notifier.load());
  return notifier;
});

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.responsable,
    required this.nombreEmployes,
    this.responsableId,
    this.responsableNom,
  });

  final int id;
  final String nom;
  final String description;
  final String responsable;
  final int nombreEmployes;
  final int? responsableId;
  final String? responsableNom;

  String get displayResponsable => responsableNom ?? responsable;

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nom: json['nom'] as String? ?? '',
        description: json['description'] as String? ?? '',
        responsable: json['responsable'] as String? ?? '',
        nombreEmployes: (json['nombreEmployes'] as num?)?.toInt() ?? 0,
        responsableId: (json['responsableId'] as num?)?.toInt(),
        responsableNom: json['responsableNom'] as String?,
      );
}

class ServiceNotifier extends ChangeNotifier {
  ServiceNotifier(this._api);

  final dynamic _api;

  List<ServiceModel> services = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resp = await _api.get<Map<String, dynamic>>('/services');
      final items = (resp.data?['items'] as List?) ?? [];
      services = items
          .whereType<Map<String, dynamic>>()
          .map(ServiceModel.fromJson)
          .toList();
    } catch (_) {
      errorMessage = 'Impossible de charger les départements.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(String nom, String description, int responsableId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/services',
        data: {'nom': nom, 'description': description, 'responsableId': responsableId},
      );
      await load();
      return true;
    } catch (_) {
      errorMessage = 'Erreur lors de la création.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, String nom, String description, int responsableId) async {
    try {
      await _api.put<Map<String, dynamic>>(
        '/services/$id',
        data: {'nom': nom, 'description': description, 'responsableId': responsableId},
      );
      await load();
      return true;
    } catch (_) {
      errorMessage = 'Erreur lors de la mise à jour.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _api.delete<void>('/services/$id');
      services.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Erreur lors de la suppression.';
      notifyListeners();
      return false;
    }
  }
}
