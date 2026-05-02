import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

final adminNotifierProvider = ChangeNotifierProvider.autoDispose<AdminNotifier>((ref) {
  return AdminNotifier(ref.read(apiServiceProvider));
});

class AdminNotifier extends ChangeNotifier {
  AdminNotifier(this._apiService);

  final ApiService _apiService;

  List<Utilisateur> users = [];
  List<String> roles = ['ADMIN', 'RH_MANAGER', 'EMPLOYEE', 'DIRECTION'];
  Map<String, bool> settings = {
    'SSO': false,
    'NOTIFICATIONS': true,
    'AUTO_LOGOUT': true,
    'TWO_FACTOR': false,
  };

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get<List<dynamic>>('/admin/users');
      final data = response.data ?? [];
      users = data
          .whereType<Map<String, dynamic>>()
          .map((u) => Utilisateur.fromJson(u))
          .toList();
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des utilisateurs';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser({
    required String email,
    required String fullName,
    required String role,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.post<Map<String, dynamic>>(
        '/admin/users',
        data: {
          'email': email,
          'fullName': fullName,
          'role': role,
          'password': password,
        },
      );
      await loadUsers();
    } catch (e) {
      errorMessage = 'Erreur lors de la création de l\'utilisateur';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required int userId,
    String? email,
    String? fullName,
    String? role,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (fullName != null) data['fullName'] = fullName;
      if (role != null) data['role'] = role;

      await _apiService.put<Map<String, dynamic>>(
        '/admin/users/$userId',
        data: data,
      );
      await loadUsers();
    } catch (e) {
      errorMessage = 'Erreur lors de la mise à jour';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.delete<void>('/admin/users/$userId');
      await loadUsers();
    } catch (e) {
      errorMessage = 'Erreur lors de la suppression';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    try {
      await _apiService.post<void>(
        '/admin/users/$userId/reset-password',
        data: {'newPassword': newPassword},
      );
    } catch (e) {
      errorMessage = 'Erreur lors de la réinitialisation du mot de passe';
    }
    notifyListeners();
  }

  Future<void> updateSettings(Map<String, bool> newSettings) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.put<Map<String, dynamic>>(
        '/admin/settings',
        data: newSettings,
      );
      settings = newSettings;
    } catch (e) {
      errorMessage = 'Erreur lors de la mise à jour des paramètres';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/admin/stats');
      return response.data ?? {};
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des statistiques';
      return {};
    }
  }
}
