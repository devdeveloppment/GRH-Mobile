package com.grhmobile.assistant;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Contrat;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.enums.Role;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.ContratRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.security.AccessControlService;
import com.grhmobile.security.AuthenticatedUserService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Outils de l'assistant RH : lecture seule, droits vérifiés ICI (côté serveur) avec
 * l'utilisateur authentifié, jamais par le modèle. Aucun SQL n'est généré : chaque outil
 * appelle des requêtes de repository fixes.
 *
 * <p>Minimisation : les résultats ne contiennent ni noms ni salaires individuels — seulement
 * des matricules, des dates, des statuts et des agrégats. Les noms sont résolus pour
 * l'affichage par {@link #noms(List)}, sans jamais être envoyés au fournisseur d'IA.
 */
@Service
public class AssistantTools {

    /** Définition déclarative d'un outil (nom, description, paramètres). */
    public record Definition(String name, String description, Map<String, Map<String, Object>> parametres) {}

    public static final List<Definition> DEFINITIONS = List.of(
        new Definition("contrats_expirant",
            "Liste les contrats actifs qui arrivent à échéance dans les N prochains jours (matricule, type, date de fin).",
            Map.of("jours", Map.of("type", "integer", "description", "Horizon en jours (1 à 365, défaut 30)"))),
        new Definition("absents_aujourdhui",
            "Donne le nombre d'employés absents aujourd'hui (congé approuvé ou absence pointée) et leurs matricules.",
            Map.of()),
        new Definition("conges_en_attente",
            "Liste les demandes de congé en attente de validation (identifiant, matricule, type, dates, jours).",
            Map.of()),
        new Definition("masse_salariale",
            "Totaux brut et net des fiches de paie calculées pour un mois (agrégat uniquement).",
            Map.of("mois", Map.of("type", "integer", "description", "Mois 1-12 (défaut : mois courant)"),
                   "annee", Map.of("type", "integer", "description", "Année (défaut : année courante)"))),
        new Definition("solde_conges",
            "Solde de congés d'un employé. Sans matricule : solde de l'utilisateur connecté.",
            Map.of("matricule", Map.of("type", "string", "description", "Matricule de l'employé (optionnel)"))));

    private final AccessControlService acl;
    private final AuthenticatedUserService authenticatedUserService;
    private final ContratRepository contratRepository;
    private final CongeRepository congeRepository;
    private final PresenceRepository presenceRepository;
    private final FichePaieRepository fichePaieRepository;
    private final EmployeRepository employeRepository;

    public AssistantTools(AccessControlService acl, AuthenticatedUserService authenticatedUserService,
                          ContratRepository contratRepository, CongeRepository congeRepository,
                          PresenceRepository presenceRepository, FichePaieRepository fichePaieRepository,
                          EmployeRepository employeRepository) {
        this.acl = acl;
        this.authenticatedUserService = authenticatedUserService;
        this.contratRepository = contratRepository;
        this.congeRepository = congeRepository;
        this.presenceRepository = presenceRepository;
        this.fichePaieRepository = fichePaieRepository;
        this.employeRepository = employeRepository;
    }

    /** Outils que l'utilisateur courant a le droit d'appeler (seuls ceux-ci sont proposés au modèle). */
    public List<Definition> autorises() {
        return DEFINITIONS.stream().filter(d -> autorise(d.name())).toList();
    }

    public boolean autorise(String outil) {
        boolean direction = authenticatedUserService.currentUser().getRole() == Role.DIRECTION;
        return switch (outil) {
            case "contrats_expirant" -> acl.can("MANAGE_EMPLOYEES");
            case "absents_aujourdhui" -> acl.can("MANAGE_LEAVES") || direction;
            case "conges_en_attente" -> acl.can("MANAGE_LEAVES");
            case "masse_salariale" -> acl.can("MANAGE_PAIE") || direction;
            case "solde_conges" -> true; // restreint au propre solde dans l'outil, sauf droit MANAGE_LEAVES
            default -> false;
        };
    }

    /** Exécute un outil après vérification des droits. Renvoie une erreur lisible plutôt qu'une exception. */
    @Transactional(readOnly = true)
    public Map<String, Object> executer(String outil, Map<String, Object> input) {
        if (!autorise(outil)) {
            return Map.of("erreur", "Accès refusé : vos droits ne permettent pas d'utiliser l'outil " + outil + ".");
        }
        try {
            return switch (outil) {
                case "contrats_expirant" -> contratsExpirant(entier(input, "jours", 30, 1, 365));
                case "absents_aujourdhui" -> absentsAujourdhui();
                case "conges_en_attente" -> congesEnAttente();
                case "masse_salariale" -> masseSalariale(
                    entier(input, "mois", LocalDate.now().getMonthValue(), 1, 12),
                    entier(input, "annee", LocalDate.now().getYear(), 2000, 2100));
                case "solde_conges" -> soldeConges(input == null ? null : (String) input.get("matricule"));
                default -> Map.of("erreur", "Outil inconnu : " + outil);
            };
        } catch (ResourceNotFoundException | IllegalArgumentException e) {
            return Map.of("erreur", e.getMessage());
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return Map.of("erreur", "Accès refusé.");
        }
    }

    /** Résolution matricule → nom, pour l'affichage uniquement (jamais transmis au modèle). */
    @Transactional(readOnly = true)
    public Map<String, String> noms(List<String> matricules) {
        Map<String, String> out = new LinkedHashMap<>();
        for (String m : matricules) {
            employeRepository.findByMatricule(m).ifPresent(e -> out.put(m, e.getPrenom() + " " + e.getNom()));
        }
        return out;
    }

    private Map<String, Object> contratsExpirant(int jours) {
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> items = new ArrayList<>();
        for (Contrat c : contratRepository.findExpiringBefore(today, today.plusDays(jours))) {
            items.add(Map.of("matricule", c.getEmploye().getMatricule(), "typeContrat", c.getTypeContrat(),
                "dateFin", c.getDateFin().toString()));
        }
        return Map.of("horizonJours", jours, "nombre", items.size(), "contrats", items);
    }

    private Map<String, Object> absentsAujourdhui() {
        LocalDate today = LocalDate.now();
        java.util.Set<String> matricules = new java.util.TreeSet<>();
        for (Conge c : congeRepository.findByStatutOrderByDateDebutDesc(StatutConge.APPROUVE)) {
            if (!c.getDateDebut().isAfter(today) && !c.getDateFin().isBefore(today)) {
                matricules.add(c.getEmploye().getMatricule());
            }
        }
        presenceRepository.findByDateBetweenOrderByDateAsc(today, today).stream()
            .filter(p -> p.getStatut() == StatutPresence.ABSENT)
            .forEach(p -> matricules.add(p.getEmploye().getMatricule()));
        return Map.of("date", today.toString(), "nombre", matricules.size(), "matricules", List.copyOf(matricules));
    }

    private Map<String, Object> congesEnAttente() {
        List<Map<String, Object>> items = new ArrayList<>();
        for (Conge c : congeRepository.findByStatutOrderByDateDebutDesc(StatutConge.EN_ATTENTE)) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", c.getId());
            m.put("matricule", c.getEmploye().getMatricule());
            m.put("type", c.getTypeConge().name());
            m.put("debut", c.getDateDebut().toString());
            m.put("fin", c.getDateFin().toString());
            m.put("jours", c.getNombreJours());
            items.add(m);
        }
        return Map.of("nombre", items.size(), "demandes", items);
    }

    private Map<String, Object> masseSalariale(int mois, int annee) {
        String periode = FichePaie.formatPeriode(YearMonth.of(annee, mois));
        List<FichePaie> fiches = fichePaieRepository.findByPeriodeOrderByEmployeNomAsc(periode);
        BigDecimal brut = BigDecimal.ZERO;
        BigDecimal net = BigDecimal.ZERO;
        boolean toutesConformes = !fiches.isEmpty();
        for (FichePaie f : fiches) {
            brut = brut.add(f.getSalaireBrut());
            net = net.add(f.getSalaireNet());
            toutesConformes &= f.isConformeReglementation();
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("periode", periode);
        m.put("nombreFiches", fiches.size());
        m.put("totalBrut", brut);
        m.put("totalNet", net);
        m.put("devise", "XOF");
        m.put("reglesValidees", toutesConformes);
        if (!toutesConformes) {
            m.put("avertissement", "Montants issus d'une simulation : règles de paie non validées par un expert-comptable.");
        }
        return m;
    }

    private Map<String, Object> soldeConges(String matricule) {
        Employe e;
        if (matricule == null || matricule.isBlank()) {
            e = employeRepository.findAll().stream()
                .filter(x -> x.getUtilisateur() != null
                    && x.getUtilisateur().getId().equals(authenticatedUserService.currentUser().getId()))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Aucune fiche employé liée à votre compte."));
        } else {
            e = employeRepository.findByMatricule(matricule.trim())
                .orElseThrow(() -> new ResourceNotFoundException("Matricule inconnu."));
            boolean soi = e.getUtilisateur() != null
                && e.getUtilisateur().getId().equals(authenticatedUserService.currentUser().getId());
            if (!soi && !acl.can("MANAGE_LEAVES")) {
                return Map.of("erreur", "Accès refusé : vous ne pouvez consulter que votre propre solde.");
            }
        }
        return Map.of("matricule", e.getMatricule(), "soldeJours", e.getSoldeConge());
    }

    private static int entier(Map<String, Object> input, String key, int defaut, int min, int max) {
        Object v = input == null ? null : input.get(key);
        if (v == null) return defaut;
        int n;
        try {
            n = v instanceof Number num ? num.intValue() : Integer.parseInt(String.valueOf(v).trim());
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("Paramètre " + key + " invalide.");
        }
        if (n < min || n > max) {
            throw new IllegalArgumentException("Paramètre " + key + " hors limites (" + min + "-" + max + ").");
        }
        return n;
    }
}
