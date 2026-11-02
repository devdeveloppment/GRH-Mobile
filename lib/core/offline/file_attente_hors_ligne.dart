import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Opérations autorisées hors ligne. Règle métier : seules les DEMANDES de l'utilisateur lui-même
/// peuvent être saisies hors ligne. La paie, les validations (approbation, refus), les paramètres et
/// les permissions exigent le réseau : elles ne sont jamais mises en file d'attente.
enum OperationHorsLigne {
  demandeConge('/conges', 'Demande de congé'),
  noteFrais('/notes-frais', 'Note de frais (sans justificatif)');

  const OperationHorsLigne(this.chemin, this.libelle);
  final String chemin;
  final String libelle;
}

enum EtatElement { enAttente, conflit }

/// Élément en attente d'envoi. [id] sert de clé d'idempotence côté serveur : un renvoi après une
/// coupure ne crée jamais de doublon.
class ElementEnAttente {
  ElementEnAttente({
    required this.id,
    required this.operation,
    required this.donnees,
    required this.utilisateurId,
    required this.creeLe,
    this.etat = EtatElement.enAttente,
    this.message,
    this.tentatives = 0,
  });

  final String id;
  final OperationHorsLigne operation;
  final Map<String, dynamic> donnees;
  final int utilisateurId;
  final DateTime creeLe;
  EtatElement etat;
  String? message;
  int tentatives;

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation.name,
        'donnees': donnees,
        'utilisateurId': utilisateurId,
        'creeLe': creeLe.toIso8601String(),
        'etat': etat.name,
        'message': message,
        'tentatives': tentatives,
      };

  factory ElementEnAttente.fromJson(Map<String, dynamic> j) => ElementEnAttente(
        id: j['id'] as String,
        operation: OperationHorsLigne.values.byName(j['operation'] as String),
        donnees: Map<String, dynamic>.from(j['donnees'] as Map),
        utilisateurId: (j['utilisateurId'] as num).toInt(),
        creeLe: DateTime.parse(j['creeLe'] as String),
        etat: EtatElement.values.byName(j['etat'] as String),
        message: j['message'] as String?,
        tentatives: (j['tentatives'] as num?)?.toInt() ?? 0,
      );
}

/// Résultat d'un envoi au serveur.
enum ResultatEnvoi { succes, reseauIndisponible, refuse, sessionInvalide }

class ReponseEnvoi {
  const ReponseEnvoi(this.resultat, [this.message]);
  final ResultatEnvoi resultat;
  final String? message;
}

/// Stockage persistant (chiffré en production, mémoire en test).
abstract class StockageFile {
  Future<List<String>> lire();
  Future<void> ecrire(List<String> elements);
}

class StockageMemoire implements StockageFile {
  List<String> _e = [];
  @override
  Future<List<String>> lire() async => List.of(_e);
  @override
  Future<void> ecrire(List<String> elements) async => _e = List.of(elements);
}

typedef Envoyeur = Future<ReponseEnvoi> Function(ElementEnAttente element);

/// File d'attente des opérations saisies hors ligne, avec synchronisation au retour du réseau.
///
/// - persistance : la file survit à la fermeture de l'application (reprise après interruption) ;
/// - ordre : envoi du plus ancien au plus récent ; arrêt au premier problème de réseau ;
/// - conflit : si le serveur refuse (règle métier, chevauchement…), l'élément passe en « conflit »
///   avec le message du serveur ; il n'est jamais renvoyé automatiquement, l'utilisateur décide ;
/// - cloisonnement : seuls les éléments de l'utilisateur connecté sont visibles et envoyés.
class FileAttenteHorsLigne extends ChangeNotifier {
  FileAttenteHorsLigne(this._stockage, this._envoyer);

  final StockageFile _stockage;
  final Envoyeur _envoyer;
  final List<ElementEnAttente> _elements = [];
  bool _charge = false;
  bool _synchronisationEnCours = false;
  bool horsLigne = false;
  DateTime? derniereSynchronisation;
  int? utilisateurCourant;

  List<ElementEnAttente> get elements =>
      _elements.where((e) => e.utilisateurId == utilisateurCourant).toList(growable: false);
  int get enAttente => elements.where((e) => e.etat == EtatElement.enAttente).length;
  int get conflits => elements.where((e) => e.etat == EtatElement.conflit).length;
  bool get synchronisationEnCours => _synchronisationEnCours;

  Future<void> charger() async {
    if (_charge) return;
    for (final s in await _stockage.lire()) {
      try {
        _elements.add(ElementEnAttente.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Élément illisible (version antérieure) : ignoré.
      }
    }
    _charge = true;
    notifyListeners();
  }

  Future<void> _sauver() => _stockage.ecrire(_elements.map((e) => jsonEncode(e.toJson())).toList());

  static String nouvelId() {
    final r = Random.secure();
    String h(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${h(8)}-${h(4)}-4${h(3)}-${h(4)}-${h(12)}';
  }

  Future<ElementEnAttente> ajouter(OperationHorsLigne operation, Map<String, dynamic> donnees) async {
    await charger();
    final u = utilisateurCourant;
    if (u == null) throw StateError('Aucun utilisateur connecté.');
    final e = ElementEnAttente(
        id: nouvelId(), operation: operation, donnees: donnees, utilisateurId: u, creeLe: DateTime.now());
    _elements.add(e);
    horsLigne = true;
    await _sauver();
    notifyListeners();
    return e;
  }

  Future<void> supprimer(String id) async {
    _elements.removeWhere((e) => e.id == id && e.utilisateurId == utilisateurCourant);
    await _sauver();
    notifyListeners();
  }

  /// Remet un élément en conflit dans la file (après correction côté serveur, par exemple).
  Future<void> reessayer(String id) async {
    for (final e in elements) {
      if (e.id == id) {
        e.etat = EtatElement.enAttente;
        e.message = null;
      }
    }
    await _sauver();
    notifyListeners();
    await synchroniser();
  }

  /// Envoie les éléments en attente. Renvoie le nombre d'éléments envoyés avec succès.
  Future<int> synchroniser() async {
    await charger();
    if (_synchronisationEnCours || utilisateurCourant == null) return 0;
    _synchronisationEnCours = true;
    notifyListeners();
    var envoyes = 0;
    try {
      final aEnvoyer = elements.where((e) => e.etat == EtatElement.enAttente).toList()
        ..sort((a, b) => a.creeLe.compareTo(b.creeLe));
      for (final e in aEnvoyer) {
        e.tentatives++;
        final r = await _envoyer(e);
        switch (r.resultat) {
          case ResultatEnvoi.succes:
            _elements.remove(e);
            envoyes++;
            horsLigne = false;
          case ResultatEnvoi.refuse:
            e.etat = EtatElement.conflit;
            e.message = r.message ?? 'Refusé par le serveur.';
            horsLigne = false;
          case ResultatEnvoi.reseauIndisponible:
            horsLigne = true;
            await _sauver();
            return envoyes;
          case ResultatEnvoi.sessionInvalide:
            await _sauver();
            return envoyes;
        }
        await _sauver();
      }
      derniereSynchronisation = DateTime.now();
      return envoyes;
    } finally {
      _synchronisationEnCours = false;
      notifyListeners();
    }
  }
}
