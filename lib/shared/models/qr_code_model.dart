class QrCodeModel {
  const QrCodeModel({
    required this.id,
    required this.employeId,
    required this.matricule,
    required this.nomComplet,
    required this.token,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int employeId;
  final String matricule;
  final String nomComplet;
  final String token;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Contenu encodé dans le QR (ce que le scanner lit)
  String get qrData => '{"employeId":$employeId,"matricule":"$matricule","token":"$token"}';

  factory QrCodeModel.fromJson(Map<String, dynamic> json) => QrCodeModel(
        id: json['id'] as int,
        employeId: json['employeId'] as int,
        matricule: json['matricule'] as String,
        nomComplet: json['nomComplet'] as String,
        token: json['token'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}
