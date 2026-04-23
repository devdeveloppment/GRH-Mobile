class Presence {
  const Presence({
    required this.id,
    required this.employeId,
    required this.date,
    this.heureArrivee,
    this.heureDepart,
    required this.statut,
  });

  final int id;
  final int employeId;
  final DateTime date;
  final DateTime? heureArrivee;
  final DateTime? heureDepart;
  final String statut;

  factory Presence.fromJson(Map<String, dynamic> json) {
    return Presence(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeId: (json['employeId'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      heureArrivee: DateTime.tryParse(json['heureArrivee'] as String? ?? ''),
      heureDepart: DateTime.tryParse(json['heureDepart'] as String? ?? ''),
      statut: json['statut'] as String? ?? 'PRESENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeId': employeId,
      'date': date.toIso8601String(),
      'heureArrivee': heureArrivee?.toIso8601String(),
      'heureDepart': heureDepart?.toIso8601String(),
      'statut': statut,
    };
  }
}
