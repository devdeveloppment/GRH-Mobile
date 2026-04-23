class Service {
  const Service({
    required this.id,
    required this.nom,
    required this.description,
    required this.responsable,
    required this.actif,
  });

  final int id;
  final String nom;
  final String description;
  final String responsable;
  final bool actif;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String? ?? '',
      responsable: json['responsable'] as String? ?? '',
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'responsable': responsable,
      'actif': actif,
    };
  }
}
