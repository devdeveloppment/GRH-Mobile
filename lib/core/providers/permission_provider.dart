import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/permission_model.dart';

final permissionNotifierProvider =
    ChangeNotifierProvider.autoDispose<PermissionNotifier>((ref) {
  final notifier = PermissionNotifier(ref);
  unawaited(notifier.loadPermissions());
  return notifier;
});

class PermissionNotifier extends ChangeNotifier {
  PermissionNotifier(this._ref);

  final Ref _ref;
  List<AppPermission> permissions = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadPermissions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final api = _ref.read(apiServiceProvider);
      final response =
          await api.get<Map<String, dynamic>>('/admin/permissions');
      final items = response.data?['items'] as List<dynamic>? ?? [];
      permissions = items
          .whereType<Map<String, dynamic>>()
          .map(AppPermission.fromJson)
          .toList();
    } catch (e) {
      errorMessage = 'Impossible de charger les permissions.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRoles(String code, List<String> roles) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.put<Map<String, dynamic>>(
        '/admin/permissions/$code/roles',
        data: {'roles': roles},
      );
      // Mise à jour locale optimiste
      permissions = permissions
          .map((p) => p.code == code
              ? AppPermission(
                  id: p.id,
                  code: p.code,
                  description: p.description,
                  roles: List<String>.from(roles),
                )
              : p)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de la mise à jour des rôles.';
      notifyListeners();
      return false;
    }
  }
}
