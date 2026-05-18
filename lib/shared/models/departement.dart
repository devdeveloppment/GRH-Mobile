class Departement {
  const Departement({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    this.parentId,
    this.parentNom,
    this.managerId,
    this.managerNom,
    required this.actif,
    this.sousDepartements = const [],
  });

  final int id;
  final String code;
  final String nom;
  final String? description;
  final int? parentId;
  final String? parentNom;
  final int? managerId;
  final String? managerNom;
  final bool actif;
  final List<Departement> sousDepartements;

  factory Departement.fromJson(Map<String, dynamic> json) {
    final children = (json['sousDepartements'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Departement.fromJson)
        .toList();
    return Departement(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      parentId: (json['parentId'] as num?)?.toInt(),
      parentNom: json['parentNom'] as String?,
      managerId: (json['managerId'] as num?)?.toInt(),
      managerNom: json['managerNom'] as String?,
      actif: json['actif'] as bool? ?? true,
      sousDepartements: children,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'nom': nom,
        'description': description,
        'parentId': parentId,
        'managerId': managerId,
      };
}
