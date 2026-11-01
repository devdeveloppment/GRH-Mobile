class FichePaie {
  const FichePaie({
    required this.id,
    required this.employeId,
    required this.periode,
    required this.salaireBrut,
    required this.cotisations,
    required this.impots,
    required this.indemnites,
    required this.salaireNet,
    this.nomEmploye,
    this.calculee = false,
    this.validee = false,
    this.autresRetenues = 0,
    this.conformeReglementation = false,
    this.avertissement,
  });

  final int id;
  final int employeId;
  final String periode;
  final double salaireBrut;
  final double cotisations;
  final double impots;
  final double indemnites;
  final double salaireNet;
  final String? nomEmploye;
  final bool calculee;
  final bool validee;
  final double autresRetenues;

  /// Faux tant que les règles de paie utilisées ne sont pas validées par un expert-comptable.
  final bool conformeReglementation;
  final String? avertissement;

  factory FichePaie.fromJson(Map<String, dynamic> json) {
    return FichePaie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeId: (json['employeId'] as num?)?.toInt() ?? 0,
      periode: json['periode'] as String? ?? '',
      salaireBrut: (json['salaireBrut'] as num?)?.toDouble() ?? 0,
      cotisations: (json['cotisations'] as num?)?.toDouble() ?? 0,
      impots: (json['impots'] as num?)?.toDouble() ?? 0,
      indemnites: (json['indemnites'] as num?)?.toDouble() ?? 0,
      salaireNet: (json['salaireNet'] as num?)?.toDouble() ?? 0,
      nomEmploye: json['nomEmploye'] as String?,
      calculee: json['calculee'] as bool? ?? false,
      validee: json['validee'] as bool? ?? false,
      autresRetenues: (json['autresRetenues'] as num?)?.toDouble() ?? 0,
      conformeReglementation: json['conformeReglementation'] as bool? ?? false,
      avertissement: json['avertissement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeId': employeId,
      'periode': periode,
      'salaireBrut': salaireBrut,
      'cotisations': cotisations,
      'impots': impots,
      'indemnites': indemnites,
      'salaireNet': salaireNet,
      'nomEmploye': nomEmploye,
      'calculee': calculee,
      'validee': validee,
      'autresRetenues': autresRetenues,
      'conformeReglementation': conformeReglementation,
      'avertissement': avertissement,
    };
  }
}
