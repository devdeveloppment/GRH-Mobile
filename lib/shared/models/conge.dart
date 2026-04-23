class Conge {
  const Conge({
    required this.id,
    required this.employeId,
    required this.typeConge,
    required this.dateDebut,
    required this.dateFin,
    required this.nombreJours,
    required this.statut,
    this.motif,
    this.commentaire,
    this.nomEmploye,
  });

  final int id;
  final int employeId;
  final String typeConge;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreJours;
  final String statut;
  final String? motif;
  final String? commentaire;
  final String? nomEmploye;

  factory Conge.fromJson(Map<String, dynamic> json) {
    return Conge(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeId: (json['employeId'] as num?)?.toInt() ?? 0,
      typeConge: json['typeConge'] as String? ?? '',
      dateDebut: DateTime.tryParse(json['dateDebut'] as String? ?? '') ?? DateTime.now(),
      dateFin: DateTime.tryParse(json['dateFin'] as String? ?? '') ?? DateTime.now(),
      nombreJours: (json['nombreJours'] as num?)?.toInt() ?? 0,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      motif: json['motif'] as String?,
      commentaire: json['commentaire'] as String?,
      nomEmploye: json['nomEmploye'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeId': employeId,
      'typeConge': typeConge,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'nombreJours': nombreJours,
      'statut': statut,
      'motif': motif,
      'commentaire': commentaire,
      'nomEmploye': nomEmploye,
    };
  }
}
