import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';

final adminNotifierProvider =
    ChangeNotifierProvider.autoDispose<AdminNotifier>((ref) {
  final notifier = AdminNotifier(ref, ref.read(apiServiceProvider));
  notifier.loadUsers();
  return notifier;
});

class AdminNotifier extends ChangeNotifier {
  AdminNotifier(this._ref, this._apiService);

  final Ref _ref;
  final dynamic _apiService;

  List<Utilisateur> users = [];
  List<String> roles = [
    'ADMIN',
    'HR_ADMIN',
    'RH_MANAGER',
    'PAYROLL_OFFICER',
    'MANAGER',
    'RECRUITER',
    'TRAINER',
    'DIRECTION',
    'EMPLOYEE',
  ];
  Map<String, bool> settings = {
    'NOTIFICATIONS': true,
    'AUTO_LOGOUT': true,
  };

  bool isLoading = false;

  /// Mot de passe temporaire du dernier compte créé (à afficher une seule fois).
  String? lastTemporaryPassword;
  String? errorMessage;

  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response =
          await _apiService.get<Map<String, dynamic>>('/admin/users');
      final data = response.data ?? <String, dynamic>{};
      // Le backend retourne {items: [...], total: N}
      final rawList = data['items'] as List<dynamic>? ??
          data['content'] as List<dynamic>? ??
          <dynamic>[];
      users = rawList
          .whereType<Map<String, dynamic>>()
          .map((u) => Utilisateur.fromJson(u))
          .toList();
    } catch (e) {
      errorMessage = 'Impossible de charger les utilisateurs.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String email,
    required String fullName,
    required String role,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = null;
    lastTemporaryPassword = null;
    notifyListeners();

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/admin/users',
        data: {
          'email': email,
          'fullName': fullName,
          'role': role,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      lastTemporaryPassword = response.data?['motDePasseTemporaire'] as String?;
      await loadUsers();
      _ref.read(dashboardNotifierProvider).refreshSilently();
      _ref.invalidate(enhancedDashboardProvider);
      return true;
    } catch (e) {
      errorMessage = _extractMessage(e, 'Erreur lors de la création de l\'utilisateur.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
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

      await _apiService.put<Map<String, dynamic>>('/admin/users/$userId',
          data: data);
      await loadUsers();
      _ref.read(dashboardNotifierProvider).refreshSilently();
      _ref.invalidate(enhancedDashboardProvider);
      return true;
    } catch (e) {
      errorMessage = _extractMessage(e, 'Erreur lors de la mise à jour.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeRole(int userId, String role) async {
    try {
      await _apiService.put<Map<String, dynamic>>(
        '/admin/users/$userId/role',
        data: {'role': role},
      );
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors du changement de rôle.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUser(int userId) async {
    try {
      await _apiService.put<Map<String, dynamic>>(
          '/admin/users/$userId/toggle');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de la modification du statut.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.delete<void>('/admin/users/$userId');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de la suppression.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response =
          await _apiService.get<Map<String, dynamic>>('/admin/stats');
      return (response.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      // Retourne des valeurs par défaut pour ne pas casser l'UI
      return {
        'activeUsers': 0,
        'totalEmployees': 0,
        'pendingLeaves': 0,
        'attendanceRate': 0,
      };
    }
  }

  void applyLoadedSettings(Map<String, bool> loaded) {
    settings.addAll(loaded);
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
    } catch (_) {
      // Paramètres mis à jour localement même si l'API échoue
      settings = newSettings;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _extractMessage(Object e, String fallback) {
    try {
      // Dio exception with response body
      final dynamic err = e;
      final msg = err?.response?.data?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }
}
