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

  Future<bool> updatePhoto(String filePath) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _ref.read(apiServiceProvider).post<void>(
        '/employees/me/photo',
        data: {'photoPath': filePath},
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
