class Poste {
  const Poste({
    required this.id,
    required this.code,
    required this.intitule,
    this.departementId,
    this.departementNom,
    this.niveau,
    this.salaireMin,
    this.salaireMax,
    this.description,
    required this.actif,
  });

  final int id;
  final String code;
  final String intitule;
  final int? departementId;
  final String? departementNom;
  final String? niveau;
  final double? salaireMin;
  final double? salaireMax;
  final String? description;
  final bool actif;

  factory Poste.fromJson(Map<String, dynamic> json) => Poste(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String? ?? '',
        intitule: json['intitule'] as String? ?? '',
        departementId: (json['departementId'] as num?)?.toInt(),
        departementNom: json['departementNom'] as String?,
        niveau: json['niveau'] as String?,
        salaireMin: (json['salaireMin'] as num?)?.toDouble(),
        salaireMax: (json['salaireMax'] as num?)?.toDouble(),
        description: json['description'] as String?,
        actif: json['actif'] as bool? ?? true,
      );
}
