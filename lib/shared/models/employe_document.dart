class EmployeDocument {
  const EmployeDocument({
    required this.id,
    required this.nom,
    required this.type,
    required this.tailleKo,
    this.url,
    required this.date,
  });

  final int id;
  final String nom;
  final String type; // 'PDF' | 'IMG'
  final int tailleKo;
  final String? url;
  final DateTime date;

  bool get isImage => type.toUpperCase() == 'IMG';

  String get tailleLabel {
    if (tailleKo >= 1024) return '${(tailleKo / 1024).toStringAsFixed(1)} Mo';
    return '$tailleKo Ko';
  }

  factory EmployeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nom: json['nom'] as String? ?? '',
      type: json['type'] as String? ?? 'PDF',
      tailleKo: (json['tailleKo'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
