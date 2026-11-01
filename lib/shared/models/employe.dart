class Employe {
  const Employe({
    this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.genre,
    this.nationalite,
    required this.email,
    this.telephone,
    required this.statut,
    this.dateEmbauche,
    required this.poste,
    required this.service,
    required this.typeContrat,
    this.adresse,
    this.dateFinContrat,
    this.photoUrl,
    this.presentAujourdHui,
    this.salaire,
    this.posteId,
    this.departementId,
    this.departement,
    this.managerMatricule,
    this.managerNom,
  });

  final int? id;
  final String matricule;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String? genre;
  final String? nationalite;
  final String email;
  final String? telephone;
  final String statut;
  final DateTime? dateEmbauche;
  final String poste;
  final String service;
  final String typeContrat;
  final String? adresse;
  final DateTime? dateFinContrat;
  final String? photoUrl;
  final bool? presentAujourdHui;
  final double? salaire;
  final int? posteId;
  final int? departementId;
  final String? departement;
  final String? managerMatricule;
  final String? managerNom;

  String get fullName => '$prenom $nom'.trim();

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      id: (json['id'] as num?)?.toInt(),
      matricule: json['matricule'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      dateNaissance: DateTime.tryParse(json['dateNaissance'] as String? ?? ''),
      genre: json['genre'] as String?,
      nationalite: json['nationalite'] as String?,
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      statut: json['statut'] as String? ?? 'ACTIF',
      dateEmbauche: DateTime.tryParse(
        json['dateEmbauche'] as String? ?? json['dateEmbauchee'] as String? ?? '',
      ),
      poste: json['poste'] as String? ?? '',
      service: json['service'] as String? ?? '',
      typeContrat: json['typeContrat'] as String? ?? '',
      adresse: json['adresse'] as String?,
      dateFinContrat: DateTime.tryParse(json['dateFin'] as String? ?? ''),
      photoUrl: json['photoUrl'] as String?,
      presentAujourdHui: json['presentAujourdHui'] as bool?,
      salaire: (json['salaire'] as num?)?.toDouble(),
      posteId: (json['posteId'] as num?)?.toInt(),
      departementId: (json['departementId'] as num?)?.toInt(),
      departement: json['departement'] as String?,
      managerMatricule: json['managerMatricule'] as String?,
      managerNom: json['managerNom'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance?.toIso8601String(),
      'genre': genre,
      'nationalite': nationalite,
      'email': email,
      'telephone': telephone,
      'statut': statut,
      'dateEmbauche': dateEmbauche?.toIso8601String(),
      'poste': poste,
      'service': service,
      'typeContrat': typeContrat,
      'adresse': adresse,
      'dateFin': dateFinContrat?.toIso8601String(),
      'photoUrl': photoUrl,
      'presentAujourdHui': presentAujourdHui,
      'salaire': salaire,
      'posteId': posteId,
      'departementId': departementId,
      'departement': departement,
      'managerMatricule': managerMatricule,
      'managerNom': managerNom,
    };
  }
}
