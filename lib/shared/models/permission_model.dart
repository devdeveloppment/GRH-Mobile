class AppPermission {
  const AppPermission({
    required this.id,
    required this.code,
    required this.description,
    required this.roles,
  });

  final int id;
  final String code;
  final String description;
  final List<String> roles;

  factory AppPermission.fromJson(Map<String, dynamic> json) {
    return AppPermission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  static const _labels = {
    'MANAGE_EMPLOYEES': 'Gestion des employés',
    'VIEW_REPORTS': 'Voir les rapports',
    'MANAGE_LEAVES': 'Gestion des congés',
    'MANAGE_PAIE': 'Gestion de la paie',
    'MANAGE_USERS': 'Gestion des utilisateurs',
  };

  String get label => _labels[code] ?? code;
}
