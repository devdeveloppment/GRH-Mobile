import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/shared/models/employe.dart';

final employeeNotifierProvider =
    ChangeNotifierProvider.autoDispose<EmployeeNotifier>((ref) {
  return EmployeeNotifier(ref);
});

class EmployeeNotifier extends ChangeNotifier {
  EmployeeNotifier(this._ref);

  final Ref _ref;
  final List<Employe> _employees = <Employe>[];

  List<Employe> get employees => List.unmodifiable(_employees);
  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  String? errorMessage;
  String query = '';
  String? statusFilter;
  String? serviceFilter;
  int _page = 1;
  static const int _limit = 20;

  List<String> get availableServices => employees
      .map((e) => e.service)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get availableStatuses => employees
      .map((e) => e.statut)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> fetchInitial() async {
    _page = 1;
    hasMore = true;
    errorMessage = null;
    _employees.clear();
    isLoading = true;
    if (query.isEmpty && statusFilter == null && serviceFilter == null) {
      final cached = await _ref.read(cacheServiceProvider).readList('employees');
      if (cached.isNotEmpty) {
        _employees
          ..clear()
          ..addAll(cached.map(Employe.fromJson));
      }
    }
    notifyListeners();
    await _fetchPage(reset: true);
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchInitial();

  Future<void> fetchMore() async {
    if (!hasMore || isFetchingMore || isLoading) return;
    isFetchingMore = true;
    notifyListeners();
    await _fetchPage();
    isFetchingMore = false;
    notifyListeners();
  }

  Future<void> _fetchPage({bool reset = false}) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/employees',
        queryParameters: {
          'page': _page,
          'limit': _limit,
          if (query.isNotEmpty) 'query': query,
          if (statusFilter != null) 'statut': statusFilter,
          if (serviceFilter != null) 'service': serviceFilter,
        },
      );

      final payload = response.data ?? <String, dynamic>{};
      final rawItems = payload['items'] as List<dynamic>? ??
          payload['content'] as List<dynamic>? ??
          payload['data'] as List<dynamic>? ??
          <dynamic>[];

      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(Employe.fromJson)
          .toList(growable: false);

      if (reset) {
        _employees
          ..clear()
          ..addAll(items);
      } else {
        _employees.addAll(items);
      }

      hasMore = items.length >= _limit;
      if (hasMore) _page += 1;

      if (query.isEmpty && statusFilter == null && serviceFilter == null && _page <= 2) {
        await _ref.read(cacheServiceProvider).writeList(
              'employees',
              _employees.map((e) => e.toJson()).toList(growable: false),
            );
      }
    } catch (e) {
      errorMessage = 'Impossible de charger les employés. Vérifiez votre connexion.';
    }
  }

  Future<bool> createEmployee(Map<String, dynamic> payload) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.post<Map<String, dynamic>>('/employees', data: payload);
      await fetchInitial();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de la création de l\'employé.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(String matricule, Map<String, dynamic> payload) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.put<Map<String, dynamic>>('/employees/$matricule', data: payload);
      await fetchInitial();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de la modification de l\'employé.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveEmployee(String matricule) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.delete<void>('/employees/$matricule');
      _employees.removeWhere((e) => e.matricule == matricule);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Erreur lors de l\'archivage de l\'employé.';
      notifyListeners();
      return false;
    }
  }

  Employe? findByMatricule(String matricule) {
    try {
      return _employees.firstWhere((e) => e.matricule == matricule);
    } catch (_) {
      return null;
    }
  }

  void setQuery(String value) {
    query = value.trim();
    unawaited(fetchInitial());
  }

  void setStatusFilter(String? value) {
    statusFilter = value == statusFilter ? null : value;
    unawaited(fetchInitial());
  }

  void setServiceFilter(String? value) {
    serviceFilter = value == serviceFilter ? null : value;
    unawaited(fetchInitial());
  }
}
