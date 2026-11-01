package com.grhmobile.config;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

import com.grhmobile.entity.Candidature;
import com.grhmobile.entity.Competence;
import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Contrat;
import com.grhmobile.entity.Departement;
import com.grhmobile.entity.Document;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Evaluation;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Formation;
import com.grhmobile.entity.Notification;
import com.grhmobile.entity.Objectif;
import com.grhmobile.entity.OffreEmploi;
import com.grhmobile.entity.ParticipationFormation;
import com.grhmobile.entity.Poste;
import com.grhmobile.entity.Presence;
import com.grhmobile.entity.ServiceEntity;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Genre;
import com.grhmobile.enums.Role;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.enums.TypeConge;
import com.grhmobile.enums.TypeContrat;
import com.grhmobile.repository.CandidatureRepository;
import com.grhmobile.repository.CompetenceRepository;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.ContratRepository;
import com.grhmobile.repository.DepartementRepository;
import com.grhmobile.repository.DocumentRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.EvaluationRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.FormationRepository;
import com.grhmobile.repository.NotificationRepository;
import com.grhmobile.repository.ObjectifRepository;
import com.grhmobile.repository.OffreEmploiRepository;
import com.grhmobile.repository.ParticipationFormationRepository;
import com.grhmobile.repository.PosteRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.repository.ServiceRepository;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.util.PasswordGenerator;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Jeu de données de démonstration, actif uniquement avec le profil Spring « demo ».
 *
 * <ul>
 *   <li>Refuse de démarrer si le profil « prod » est aussi actif.</li>
 *   <li>Idempotent : chaque section n'est créée que si sa table est vide.</li>
 *   <li>Mot de passe des comptes de démo : propriété {@code app.demo.password}
 *       (variable {@code DEMO_PASSWORD}). Absente : mot de passe temporaire généré,
 *       affiché dans les logs, changement obligatoire.</li>
 * </ul>
 * Toutes les personnes sont fictives.
 */
@Component
@Profile("demo")
@Order(2)
public class DemoDataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);

    private final Environment environment;
    private final String demoPassword;
    private final PasswordEncoder passwordEncoder;
    private final UtilisateurRepository utilisateurRepository;
    private final ServiceRepository serviceRepository;
    private final EmployeRepository employeRepository;
    private final PresenceRepository presenceRepository;
    private final CongeRepository congeRepository;
    private final FichePaieRepository fichePaieRepository;
    private final DocumentRepository documentRepository;
    private final CompetenceRepository competenceRepository;
    private final DepartementRepository departementRepository;
    private final PosteRepository posteRepository;
    private final OffreEmploiRepository offreRepository;
    private final CandidatureRepository candidatureRepository;
    private final FormationRepository formationRepository;
    private final ParticipationFormationRepository participationRepository;
    private final EvaluationRepository evaluationRepository;
    private final ContratRepository contratRepository;
    private final NotificationRepository notificationRepository;
    private final ObjectifRepository objectifRepository;

    public DemoDataSeeder(
        Environment environment,
        @Value("${app.demo.password:}") String demoPassword,
        PasswordEncoder passwordEncoder,
        UtilisateurRepository utilisateurRepository,
        ServiceRepository serviceRepository,
        EmployeRepository employeRepository,
        PresenceRepository presenceRepository,
        CongeRepository congeRepository,
        FichePaieRepository fichePaieRepository,
        DocumentRepository documentRepository,
        CompetenceRepository competenceRepository,
        DepartementRepository departementRepository,
        PosteRepository posteRepository,
        OffreEmploiRepository offreRepository,
        CandidatureRepository candidatureRepository,
        FormationRepository formationRepository,
        ParticipationFormationRepository participationRepository,
        EvaluationRepository evaluationRepository,
        ContratRepository contratRepository,
        NotificationRepository notificationRepository,
        ObjectifRepository objectifRepository
    ) {
        if (environment.acceptsProfiles(Profiles.of("prod"))) {
            throw new IllegalStateException("Le profil « demo » est interdit avec le profil « prod ».");
        }
        this.environment = environment;
        this.demoPassword = demoPassword;
        this.passwordEncoder = passwordEncoder;
        this.utilisateurRepository = utilisateurRepository;
        this.serviceRepository = serviceRepository;
        this.employeRepository = employeRepository;
        this.presenceRepository = presenceRepository;
        this.congeRepository = congeRepository;
        this.fichePaieRepository = fichePaieRepository;
        this.documentRepository = documentRepository;
        this.competenceRepository = competenceRepository;
        this.departementRepository = departementRepository;
        this.posteRepository = posteRepository;
        this.offreRepository = offreRepository;
        this.candidatureRepository = candidatureRepository;
        this.formationRepository = formationRepository;
        this.participationRepository = participationRepository;
        this.evaluationRepository = evaluationRepository;
        this.contratRepository = contratRepository;
        this.notificationRepository = notificationRepository;
        this.objectifRepository = objectifRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        log.warn("Profil « demo » actif : données FICTIVES de démonstration (profils actifs : {}).",
            String.join(",", environment.getActiveProfiles()));

        if (employeRepository.count() == 0) {
            seedCore();
        }
        List<Employe> employees = employeRepository.findAll();
        if (employees.isEmpty()) {
            return;
        }
        Map<String, Departement> departements = seedDepartementsAndPostes(employees);
        seedRecrutement(departements);
        seedFormations(employees);
        seedEvaluations(employees);
        seedContrats(employees);
        seedObjectifs(employees);
        seedNotifications();
        seedCurrentPresencesAndPaie(employees);
    }

    // ── Socle : services, comptes et employés ────────────────────────────────

    private void seedCore() {
        String password = demoPassword;
        boolean mustChange = false;
        if (password == null || password.isBlank()) {
            password = PasswordGenerator.temporaryPassword();
            mustChange = true;
            log.warn("app.demo.password absent : mot de passe temporaire des comptes de démo = {} "
                + "(changement obligatoire à la première connexion).", password);
        }

        ServiceEntity finance = saveService("Finance", "Gestion comptable et trésorerie", "Kokou Mensah");
        ServiceEntity rh = saveService("Ressources Humaines", "Administration du personnel", "Aminata Sanni");
        ServiceEntity commercial = saveService("Commercial", "Développement du portefeuille client", "Yaw Lawson");
        ServiceEntity operations = saveService("Opérations", "Pilotage des activités terrain", "Akouvi Edorh");

        Utilisateur hrManager = saveUser("Aminata", "Sanni", "rh@grh-mobile.com", Role.RH_MANAGER, password, mustChange);
        Utilisateur employeeUser = saveUser("Ama", "Tossou", "employee@grh-mobile.com", Role.EMPLOYEE, password, mustChange);
        Utilisateur direction = saveUser("Komi", "Tsevi", "direction@grh-mobile.com", Role.DIRECTION, password, mustChange);

        Employe e1 = saveEmployee(employeeUser, "GRH-AT-240421-001", "Tossou", "Ama", employeeUser.getEmail(), "Développeuse Mobile", rh, 450000, Genre.FEMME);
        Employe e2 = saveEmployee(null, "GRH-KM-240421-002", "Mensah", "Kokou", "kokou.mensah@grh-mobile.com", "Comptable Senior", finance, 520000, Genre.HOMME);
        Employe e3 = saveEmployee(null, "GRH-YL-240421-003", "Lawson", "Yaw", "yaw.lawson@grh-mobile.com", "Business Developer", commercial, 390000, Genre.HOMME);
        Employe e4 = saveEmployee(null, "GRH-AE-240421-004", "Edorh", "Akouvi", "akouvi.edorh@grh-mobile.com", "Responsable Opérations", operations, 610000, Genre.FEMME);
        Employe e5 = saveEmployee(null, "GRH-AS-240421-005", "Sanni", "Aminata", hrManager.getEmail(), "RH Manager", rh, 700000, Genre.FEMME);
        Employe e6 = saveEmployee(null, "GRH-KT-240421-006", "Tsevi", "Komi", direction.getEmail(), "Directeur Général", operations, 950000, Genre.HOMME);

        List<Employe> employees = List.of(e1, e2, e3, e4, e5, e6);
        seedConges(e1, e3, e5);
        seedDocuments(employees);
        seedCompetences(employees);
    }

    private ServiceEntity saveService(String nom, String description, String responsable) {
        ServiceEntity service = new ServiceEntity();
        service.setNom(nom);
        service.setDescription(description);
        service.setResponsable(responsable);
        return serviceRepository.save(service);
    }

    private Utilisateur saveUser(String nom, String prenom, String email, Role role, String password, boolean mustChange) {
        Utilisateur user = new Utilisateur();
        user.setNom(nom);
        user.setPrenom(prenom);
        user.setEmail(email);
        user.setRole(role);
        user.setMotDePasse(passwordEncoder.encode(password));
        user.setDoitChangerMotDePasse(mustChange);
        user.setDateCreation(OffsetDateTime.now().minusMonths(4));
        return utilisateurRepository.save(user);
    }

    private Employe saveEmployee(Utilisateur utilisateur, String matricule, String nom, String prenom, String email,
                                 String poste, ServiceEntity service, long salaire, Genre genre) {
        Employe employe = new Employe();
        employe.setMatricule(matricule);
        employe.setNom(nom);
        employe.setPrenom(prenom);
        employe.setEmail(email);
        employe.setTelephone("+228 90 00 00 00");
        employe.setStatut("ACTIF");
        employe.setDateEmbauche(LocalDate.now().minusMonths(18));
        employe.setDateNaissance(LocalDate.now().minusYears(29));
        employe.setGenre(genre);
        employe.setNationalite("Togolaise");
        employe.setPoste(poste);
        employe.setService(service);
        employe.setTypeContrat(TypeContrat.CDI);
        employe.setAdresse("Lomé, Togo");
        employe.setSalaireBrutBase(BigDecimal.valueOf(salaire));
        employe.setUtilisateur(utilisateur);
        return employeRepository.save(employe);
    }

    private void seedConges(Employe e1, Employe e3, Employe e5) {
        congeRepository.save(conge(e1, TypeConge.ANNUEL, 5, 8, 4, StatutConge.EN_ATTENTE, "Repos annuel", null));
        congeRepository.save(conge(e3, TypeConge.MALADIE, -10, -8, 3, StatutConge.APPROUVE, "Arrêt médical", null));
        congeRepository.save(conge(e5, TypeConge.SANS_SOLDE, 12, 14, 3, StatutConge.REFUSE, null,
            "Période sensible pour la clôture RH."));
    }

    private Conge conge(Employe e, TypeConge type, int debut, int fin, int jours, StatutConge statut,
                        String motif, String commentaire) {
        Conge c = new Conge();
        c.setEmploye(e);
        c.setTypeConge(type);
        c.setDateDebut(LocalDate.now().plusDays(debut));
        c.setDateFin(LocalDate.now().plusDays(fin));
        c.setNombreJours(jours);
        c.setStatut(statut);
        c.setMotif(motif);
        c.setCommentaire(commentaire);
        return c;
    }

    private void seedDocuments(List<Employe> employees) {
        String[][] types = {
            {"CV", "PDF", "1240"}, {"Diplôme Master", "PDF", "1820"}, {"Carte d'identité", "PDF", "820"},
            {"Contrat de travail", "PDF", "2100"}, {"Certificat de travail", "PDF", "980"}, {"Photo d'identité", "IMG", "640"},
        };
        for (Employe employe : employees) {
            for (String[] t : types) {
                Document doc = new Document();
                doc.setEmploye(employe);
                doc.setNom(t[0] + " - " + employe.getPrenom() + " " + employe.getNom() + "." + (t[1].equals("IMG") ? "jpg" : "pdf"));
                doc.setType(t[1]);
                doc.setTailleKo(Integer.parseInt(t[2]));
                documentRepository.save(doc);
            }
        }
    }

    private void seedCompetences(List<Employe> employees) {
        String[][] competences = {
            {"Communication", "85"}, {"Gestion de projet", "75"}, {"Travail en équipe", "90"},
            {"Maîtrise des outils bureautiques", "80"}, {"Analyse et résolution de problèmes", "70"},
        };
        for (Employe employe : employees) {
            for (String[] c : competences) {
                Competence comp = new Competence();
                comp.setEmploye(employe);
                comp.setLibelle(c[0]);
                comp.setNiveau(Integer.parseInt(c[1]));
                competenceRepository.save(comp);
            }
        }
    }

    // ── Organisation ─────────────────────────────────────────────────────────

    private Map<String, Departement> seedDepartementsAndPostes(List<Employe> employees) {
        if (departementRepository.count() == 0) {
            Map<String, String[]> data = Map.of(
                "FIN", new String[] {"Finance", "Gestion comptable et trésorerie"},
                "RH", new String[] {"Ressources Humaines", "Administration du personnel"},
                "COM", new String[] {"Commercial", "Développement du portefeuille client"},
                "OPS", new String[] {"Opérations", "Pilotage des activités terrain"});
            data.forEach((code, v) -> {
                Departement d = new Departement();
                d.setCode(code);
                d.setNom(v[0]);
                d.setDescription(v[1]);
                departementRepository.save(d);
            });
        }
        Map<String, Departement> byCode = new java.util.HashMap<>();
        departementRepository.findAll().forEach(d -> byCode.put(d.getCode(), d));
        Map<String, Departement> byNom = new java.util.HashMap<>();
        departementRepository.findAll().forEach(d -> byNom.put(d.getNom(), d));

        if (posteRepository.count() == 0) {
            savePoste("DEV-MOB", "Développeur Mobile", byCode.get("RH"), "Confirmé", 400000, 500000);
            savePoste("CPT-SR", "Comptable Senior", byCode.get("FIN"), "Senior", 480000, 560000);
            savePoste("BD-COM", "Business Developer", byCode.get("COM"), "Confirmé", 350000, 420000);
            savePoste("OPS-RSP", "Responsable Opérations", byCode.get("OPS"), "Senior", 560000, 650000);
            savePoste("RH-MGR", "RH Manager", byCode.get("RH"), "Senior", 650000, 750000);
            savePoste("DG", "Directeur Général", byCode.get("OPS"), "Direction", 900000, 1000000);
        }
        Map<String, Poste> postes = new java.util.HashMap<>();
        posteRepository.findAll().forEach(p -> postes.put(p.getIntitule(), p));

        for (Employe e : employees) {
            boolean changed = false;
            if (e.getDepartement() == null && e.getService() != null && byNom.containsKey(e.getService().getNom())) {
                e.setDepartement(byNom.get(e.getService().getNom()));
                changed = true;
            }
            if (e.getPosteRef() == null) {
                Poste p = postes.get(e.getPoste());
                if (p == null && "Développeuse Mobile".equals(e.getPoste())) {
                    p = postes.get("Développeur Mobile");
                }
                if (p != null) {
                    e.setPosteRef(p);
                    changed = true;
                }
            }
            if (changed) {
                employeRepository.save(e);
            }
        }
        return byCode;
    }

    private void savePoste(String code, String intitule, Departement dep, String niveau, long min, long max) {
        Poste p = new Poste();
        p.setCode(code);
        p.setIntitule(intitule);
        p.setDepartement(dep);
        p.setNiveau(niveau);
        p.setSalaireMin(BigDecimal.valueOf(min));
        p.setSalaireMax(BigDecimal.valueOf(max));
        posteRepository.save(p);
    }

    // ── Recrutement, formations, évaluations, contrats ───────────────────────

    private void seedRecrutement(Map<String, Departement> departements) {
        if (offreRepository.count() > 0) {
            return;
        }
        OffreEmploi flutter = offre("Développeur Flutter confirmé",
            "Développement et maintenance de l'application mobile RH.", "PUBLIEE", 30, departements.get("RH"));
        OffreEmploi bd = offre("Business Developer",
            "Prospection de nouveaux clients et suivi du portefeuille.", "PUBLIEE", 45, departements.get("COM"));
        offre("Comptable Senior", "Clôtures mensuelles et reporting financier.", "BROUILLON", 60, departements.get("FIN"));

        candidature(flutter, "Lawale", "Sena", "sena.lawale@example.com", "RECUE", null, null);
        candidature(flutter, "Kpodar", "Jean", "jean.kpodar@example.com", "ENTRETIEN", 4, "Bon profil technique");
        candidature(bd, "Adjovi", "Marie", "marie.adjovi@example.com", "RECUE", null, null);
    }

    private OffreEmploi offre(String titre, String description, String statut, int jours, Departement dep) {
        OffreEmploi o = new OffreEmploi();
        o.setTitre(titre);
        o.setDescription(description);
        o.setStatut(statut);
        o.setDateLimite(LocalDate.now().plusDays(jours));
        o.setDepartement(dep);
        return offreRepository.save(o);
    }

    private void candidature(OffreEmploi offre, String nom, String prenom, String email, String statut,
                             Integer note, String commentaire) {
        Candidature c = new Candidature();
        c.setOffre(offre);
        c.setNom(nom);
        c.setPrenom(prenom);
        c.setEmail(email);
        c.setStatut(statut);
        c.setNote(note);
        c.setCommentaire(commentaire);
        candidatureRepository.save(c);
    }

    private void seedFormations(List<Employe> employees) {
        if (formationRepository.count() > 0) {
            return;
        }
        formation("Sécurité au travail", "Prévention des risques et premiers secours.", "SECURITE", 8, "PLANIFIEE", 14, 15);
        Formation excel = formation("Excel avancé", "Tableaux croisés, formules et automatisation.", "BUREAUTIQUE", 16, "EN_COURS", -3, 4);
        formation("Leadership d'équipe", "Animer et motiver une équipe.", "MANAGEMENT", 12, "PLANIFIEE", 30, 32);
        employees.stream().limit(2).forEach(e -> {
            ParticipationFormation p = new ParticipationFormation();
            p.setFormation(excel);
            p.setEmploye(e);
            participationRepository.save(p);
        });
    }

    private Formation formation(String titre, String description, String type, int heures, String statut, int debut, int fin) {
        Formation f = new Formation();
        f.setTitre(titre);
        f.setDescription(description);
        f.setType(type);
        f.setFormateur("Formation interne");
        f.setDureeHeures(heures);
        f.setStatut(statut);
        f.setDateDebut(LocalDate.now().plusDays(debut));
        f.setDateFin(LocalDate.now().plusDays(fin));
        return formationRepository.save(f);
    }

    private void seedEvaluations(List<Employe> employees) {
        if (evaluationRepository.count() > 0) {
            return;
        }
        Utilisateur rh = utilisateurRepository.findByEmailIgnoreCase("rh@grh-mobile.com").orElse(null);
        Utilisateur direction = utilisateurRepository.findByEmailIgnoreCase("direction@grh-mobile.com").orElse(null);
        // Notes sur 10 (contrainte evaluations_note_check).
        evaluation(employees.get(0), rh, "2026-S1", 8, "VALIDEE", "Bonne progression sur l'année.");
        if (employees.size() > 2) {
            evaluation(employees.get(2), direction, "2026-S1", 7, "SOUMISE", "Objectifs partiellement atteints.");
        }
        if (employees.size() > 1) {
            evaluation(employees.get(1), direction, "2026-S2", 0, "BROUILLON", null);
        }
    }

    private void evaluation(Employe e, Utilisateur evaluateur, String periode, int note, String statut, String commentaire) {
        Evaluation ev = new Evaluation();
        ev.setEmploye(e);
        ev.setEvaluateur(evaluateur);
        ev.setPeriode(periode);
        ev.setNote(note);
        ev.setStatut(statut);
        ev.setType("SEMESTRIELLE");
        ev.setCommentaire(commentaire);
        evaluationRepository.save(ev);
    }

    private void seedContrats(List<Employe> employees) {
        if (contratRepository.count() > 0) {
            return;
        }
        for (int i = 0; i < employees.size(); i++) {
            Employe e = employees.get(i);
            Contrat c = new Contrat();
            c.setEmploye(e);
            c.setDateDebut(e.getDateEmbauche() != null ? e.getDateEmbauche() : LocalDate.now().minusYears(1));
            c.setSalaireBrut(e.getSalaireBrutBase());
            c.setPoste(e.getPosteRef());
            c.setDepartement(e.getDepartement());
            // Un CDD expirant bientôt pour alimenter « Contrats expirant ».
            if (i == 1) {
                c.setTypeContrat("CDD");
                c.setDateFin(LocalDate.now().plusDays(20));
            } else {
                c.setTypeContrat("CDI");
            }
            contratRepository.save(c);
        }
    }

    private void seedObjectifs(List<Employe> employees) {
        if (objectifRepository.count() > 0) {
            return;
        }
        for (Employe e : employees) {
            objectif(e, "Livrer le module de présences", "Mettre en production le suivi des présences.", 60);
            objectif(e, "Formation continue", "Suivre au moins une formation par trimestre.", 90);
        }
    }

    private void objectif(Employe e, String titre, String description, int jours) {
        Objectif o = new Objectif();
        o.setEmploye(e);
        o.setTitre(titre);
        o.setDescription(description);
        o.setDateEcheance(LocalDate.now().plusDays(jours));
        objectifRepository.save(o);
    }

    private void seedNotifications() {
        if (notificationRepository.count() > 0) {
            return;
        }
        for (Utilisateur u : utilisateurRepository.findAll()) {
            Notification n = new Notification();
            n.setUtilisateur(u);
            switch (u.getRole()) {
                case ADMIN, RH_MANAGER -> {
                    n.setTitre("Congé en attente");
                    n.setMessage("Une demande de congé annuel attend votre validation.");
                    n.setType("CONGE");
                    n.setRedirectTo("/rh/conges");
                }
                case DIRECTION -> {
                    n.setTitre("Rapport mensuel");
                    n.setMessage("Le rapport RH du mois est disponible.");
                    n.setType("RAPPORT");
                    n.setRedirectTo("/rh/rapports");
                }
                default -> {
                    n.setTitre("Bienvenue");
                    n.setMessage("Votre espace employé est prêt.");
                    n.setType("INFO");
                }
            }
            notificationRepository.save(n);
        }
    }

    // ── Données « du moment » : présences de la semaine et paie du mois ──────

    private void seedCurrentPresencesAndPaie(List<Employe> employees) {
        for (Employe employe : employees) {
            for (int daysBack = 0; daysBack < 7; daysBack++) {
                LocalDate date = LocalDate.now().minusDays(daysBack);
                if (date.getDayOfWeek().getValue() >= 6
                    || presenceRepository.findByEmployeIdAndDate(employe.getId(), date).isPresent()) {
                    continue;
                }
                Presence presence = new Presence();
                presence.setEmploye(employe);
                presence.setDate(date);
                presence.setStatut(StatutPresence.PRESENT);
                presence.setHeureArrivee(LocalDateTime.of(date, LocalTime.of(8, 2)));
                presence.setHeureDepart(LocalDateTime.of(date, LocalTime.of(17, 5)));
                presenceRepository.save(presence);
            }
        }

        // Fiches de démonstration : montants fictifs, NON conformes à la réglementation
        // (le moteur de paie localisé est en attente de validation par un expert-comptable).
        String periode = FichePaie.formatPeriode(YearMonth.now());
        for (Employe employe : employees) {
            if (fichePaieRepository.findByEmployeIdAndPeriode(employe.getId(), periode).isPresent()) {
                continue;
            }
            BigDecimal brut = employe.getSalaireBrutBase();
            FichePaie payslip = new FichePaie();
            payslip.setEmploye(employe);
            payslip.setPeriode(periode);
            payslip.setSalaireBrut(brut);
            payslip.setCotisations(BigDecimal.ZERO);
            payslip.setImpots(BigDecimal.ZERO);
            payslip.setIndemnites(BigDecimal.ZERO);
            payslip.setSalaireNet(brut);
            payslip.setCalculee(true);
            fichePaieRepository.save(payslip);
        }
    }
}
