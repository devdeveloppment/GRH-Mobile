import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/employe.dart';

/// Profil complet de l'employé connecté — GET /employees/me
final profileProvider =
    FutureProvider.autoDispose<Employe>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get<Map<String, dynamic>>('/employees/me');
  return Employe.fromJson(response.data ?? <String, dynamic>{});
});

/// Mutation du profil (photo, coordonnées)
final profileUpdateProvider =
    ChangeNotifierProvider.autoDispose<ProfileUpdateNotifier>((ref) {
  return ProfileUpdateNotifier(ref);
});

class ProfileUpdateNotifier extends ChangeNotifier {
  ProfileUpdateNotifier(this._ref);

  final Ref _ref;
  bool isSaving = false;
  String? error;

  /// Upload de photo avec multipart form data
  Future<bool> updatePhoto(String filePath) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final dio = _ref.read(apiServiceProvider);
      
      // Créer FormData avec MultipartFile
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          filePath,
          filename: 'photo.jpg',
        ),
      });

      // POST vers /api/profile/photo
      final response = await dio.post<Map<String, dynamic>>(
        '/profile/photo',
        data: formData,
      );

      if (response.statusCode == 200) {
        // Rafraîchir le profil après upload
        _ref.invalidate(profileProvider);
        return true;
      }
      
      error = 'Erreur lors de l\'upload de la photo';
      return false;
    } catch (e) {
      error = 'Erreur: ${e.toString()}';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Supprimer la photo de profil
  Future<bool> deletePhoto() async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final dio = _ref.read(apiServiceProvider);
      await dio.delete('/profile/photo');
      _ref.invalidate(profileProvider);
      return true;
    } catch (e) {
      error = 'Erreur: ${e.toString()}';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateInfo(Map<String, dynamic> payload) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _ref.read(apiServiceProvider).put<void>(
        '/employees/me',
        data: payload,
      );
      _ref.invalidate(profileProvider);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

