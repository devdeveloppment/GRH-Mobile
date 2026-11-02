import 'package:flutter_test/flutter_test.dart';
import 'package:grh_mobile/core/offline/file_attente_hors_ligne.dart';

/// Serveur simulé : réseau coupable, refus métier, mémorisation des clés d'idempotence.
class ServeurSimule {
  bool reseau = true;
  final Set<String> clesTraitees = {};
  final List<String> recus = [];
  String? refuserMotif;
  int appels = 0;

  Future<ReponseEnvoi> envoyer(ElementEnAttente e) async {
    appels++;
    if (!reseau) return const ReponseEnvoi(ResultatEnvoi.reseauIndisponible);
    if (refuserMotif != null && e.donnees['motif'] == 'conflit') {
      return ReponseEnvoi(ResultatEnvoi.refuse, refuserMotif);
    }
    // Rejeu : le serveur renvoie la réponse d'origine sans créer de doublon.
    if (clesTraitees.add(e.id)) recus.add(e.donnees['motif'] as String);
    return const ReponseEnvoi(ResultatEnvoi.succes);
  }
}

void main() {
  late StockageMemoire stockage;
  late ServeurSimule serveur;

  FileAttenteHorsLigne nouvelleFile() => FileAttenteHorsLigne(stockage, serveur.envoyer)..utilisateurCourant = 7;

  setUp(() {
    stockage = StockageMemoire();
    serveur = ServeurSimule();
  });

  test('perte de réseau : les opérations restent en file, puis partent au retour du réseau', () async {
    final file = nouvelleFile();
    serveur.reseau = false;
    await file.ajouter(OperationHorsLigne.demandeConge, {'motif': 'a'});
    await file.ajouter(OperationHorsLigne.noteFrais, {'motif': 'b'});
    expect(await file.synchroniser(), 0);
    expect(file.enAttente, 2);
    expect(file.horsLigne, isTrue);
    expect(serveur.appels, 1, reason: 'arrêt au premier échec réseau');

    serveur.reseau = true;
    expect(await file.synchroniser(), 2);
    expect(file.enAttente, 0);
    expect(serveur.recus, ['a', 'b'], reason: 'ordre de saisie respecté');
    expect(file.horsLigne, isFalse);
  });

  test('reprise après interruption : la file persiste entre deux lancements', () async {
    serveur.reseau = false;
    final avant = nouvelleFile();
    await avant.ajouter(OperationHorsLigne.demandeConge, {'motif': 'persistant'});
    // « Redémarrage » : nouvelle instance sur le même stockage.
    serveur.reseau = true;
    final apres = nouvelleFile();
    await apres.charger();
    expect(apres.enAttente, 1);
    await apres.synchroniser();
    expect(serveur.recus, ['persistant']);
  });

  test('envoi interrompu après traitement serveur : pas de doublon grâce à la clé', () async {
    final file = nouvelleFile();
    final e = await file.ajouter(OperationHorsLigne.demandeConge, {'motif': 'unique'});
    // Le serveur a traité la requête mais la réponse s'est perdue.
    await serveur.envoyer(e);
    await file.synchroniser();
    expect(serveur.recus, ['unique']);
    expect(file.enAttente, 0);
  });

  test('conflit : refusé par le serveur, conservé avec le motif, jamais renvoyé automatiquement', () async {
    final file = nouvelleFile();
    serveur.refuserMotif = 'Une demande de congé existe déjà sur cette période.';
    await file.ajouter(OperationHorsLigne.demandeConge, {'motif': 'conflit'});
    await file.ajouter(OperationHorsLigne.demandeConge, {'motif': 'ok'});
    await file.synchroniser();
    expect(file.conflits, 1);
    expect(file.elements.single.message, contains('existe déjà'));
    expect(serveur.recus, ['ok'], reason: 'un conflit ne bloque pas les opérations suivantes');
    final appels = serveur.appels;
    await file.synchroniser();
    expect(serveur.appels, appels, reason: 'pas de renvoi automatique d\'un conflit');
    // Décision de l'utilisateur : supprimer.
    await file.supprimer(file.elements.single.id);
    expect(file.elements, isEmpty);
  });

  test('cloisonnement : un autre utilisateur ne voit ni n\'envoie les opérations', () async {
    serveur.reseau = false;
    final file = nouvelleFile();
    await file.ajouter(OperationHorsLigne.demandeConge, {'motif': 'de 7'});
    serveur.reseau = true;
    file.utilisateurCourant = 8;
    expect(file.elements, isEmpty);
    expect(await file.synchroniser(), 0);
    expect(serveur.recus, isEmpty);
    file.utilisateurCourant = 7;
    expect(await file.synchroniser(), 1);
  });

  test('identifiants uniques au format UUID v4', () {
    final ids = List.generate(500, (_) => FileAttenteHorsLigne.nouvelId());
    expect(ids.toSet().length, 500);
    expect(ids.first, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$')));
  });

  test('seules les demandes personnelles sont autorisées hors ligne', () {
    expect(OperationHorsLigne.values.map((o) => o.chemin), ['/conges', '/notes-frais']);
  });
}
