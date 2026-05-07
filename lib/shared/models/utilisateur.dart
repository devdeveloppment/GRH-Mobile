enum UserRole {
  admin,
  rhManager,
  employee,
  direction;

  static UserRole fromApi(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'RH_MANAGER':
        return UserRole.rhManager;
      case 'EMPLOYEE':
        return UserRole.employee;
      case 'DIRECTION':
        return UserRole.direction;
      default:
        return UserRole.employee;
    }
  }
}

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.rhManager:
        return 'RH_MANAGER';
      case UserRole.employee:
        return 'EMPLOYEE';
      case UserRole.direction:
        return 'DIRECTION';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administration';
      case UserRole.rhManager:
        return 'Responsable RH';
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

  String get fullName => '$prenom $nom'.trim();

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
    };
  }
}
