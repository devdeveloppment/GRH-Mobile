enum UserRole {
  superAdmin,
  admin,
  hrAdmin,
  rhManager,
  payrollOfficer,
  manager,
  recruiter,
  trainer,
  employee,
  direction;

  static UserRole fromApi(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'HR_ADMIN':
        return UserRole.hrAdmin;
      case 'RH_MANAGER':
        return UserRole.rhManager;
      case 'PAYROLL_OFFICER':
        return UserRole.payrollOfficer;
      case 'MANAGER':
        return UserRole.manager;
      case 'RECRUITER':
        return UserRole.recruiter;
      case 'TRAINER':
        return UserRole.trainer;
      case 'EMPLOYEE':
        return UserRole.employee;
      case 'DIRECTION':
        return UserRole.direction;
      default:
        return UserRole.employee;
    }
  }

  bool get isHrFamily =>
      this == UserRole.superAdmin ||
      this == UserRole.admin ||
      this == UserRole.hrAdmin ||
      this == UserRole.rhManager;

  bool get isAdmin =>
      this == UserRole.superAdmin || this == UserRole.admin;
}

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.hrAdmin:
        return 'HR_ADMIN';
      case UserRole.rhManager:
        return 'RH_MANAGER';
      case UserRole.payrollOfficer:
        return 'PAYROLL_OFFICER';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.recruiter:
        return 'RECRUITER';
      case UserRole.trainer:
        return 'TRAINER';
      case UserRole.employee:
        return 'EMPLOYEE';
      case UserRole.direction:
        return 'DIRECTION';
    }
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Administration';
      case UserRole.hrAdmin:
        return 'Admin RH';
      case UserRole.rhManager:
        return 'Responsable RH';
      case UserRole.payrollOfficer:
        return 'Gestionnaire Paie';
      case UserRole.manager:
        return 'Manager';
      case UserRole.recruiter:
        return 'Recruteur';
      case UserRole.trainer:
        return 'Formateur';
      case UserRole.employee:
        return 'Employé';
      case UserRole.direction:
        return 'Direction';
    }
  }
}

class Utilisateur {
  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.actif,
    required this.dateCreation,
    this.avatarUrl,
    this.photoUrl,
    this.doitChangerMotDePasse = false,
    this.permissions = const <String>[],
  });

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final bool actif;
  final DateTime dateCreation;
  final String? avatarUrl;
  final String? photoUrl;

  /// Vrai tant que l'utilisateur n'a pas remplacé son mot de passe temporaire.
  final bool doitChangerMotDePasse;

  /// Permissions fonctionnelles effectives (MANAGE_EMPLOYEES, MANAGE_PAIE…).
  final List<String> permissions;

  String get fullName => '$prenom $nom'.trim();

  bool hasPermission(String code) =>
      role == UserRole.admin || role == UserRole.superAdmin || permissions.contains(code);

  Utilisateur copyWith({bool? doitChangerMotDePasse, List<String>? permissions, String? photoUrl}) {
    return Utilisateur(
      id: id,
      nom: nom,
      prenom: prenom,
      email: email,
      role: role,
      actif: actif,
      dateCreation: dateCreation,
      avatarUrl: avatarUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      doitChangerMotDePasse: doitChangerMotDePasse ?? this.doitChangerMotDePasse,
      permissions: permissions ?? this.permissions,
    );
  }

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromApi(json['role'] as String?),
      actif: json['actif'] as bool? ?? true,
      dateCreation: DateTime.tryParse(
            json['dateCreation'] as String? ??
                json['dateCréation'] as String? ??
                '',
          ) ??
          DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      photoUrl: json['photoUrl'] as String?,
      doitChangerMotDePasse: json['doitChangerMotDePasse'] as bool? ?? false,
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role.apiValue,
      'actif': actif,
      'dateCreation': dateCreation.toIso8601String(),
      'avatarUrl': avatarUrl,
      'photoUrl': photoUrl,
      'doitChangerMotDePasse': doitChangerMotDePasse,
      'permissions': permissions,
    };
  }
}
