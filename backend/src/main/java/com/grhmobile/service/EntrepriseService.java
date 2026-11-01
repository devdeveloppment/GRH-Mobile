package com.grhmobile.service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.grhmobile.entity.AppSetting;
import com.grhmobile.entity.Entreprise;
import com.grhmobile.entity.ParametreRh;
import com.grhmobile.entity.RubriquePaie;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Role;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.AppSettingRepository;
import com.grhmobile.repository.EntrepriseRepository;
import com.grhmobile.repository.ParametreRhRepository;
import com.grhmobile.repository.RubriquePaieRepository;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.tenant.TenantContext;
import com.grhmobile.util.PasswordGenerator;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Gestion des entreprises clientes (plateforme SaaS). Chaque création initialise les données
 * propres à l'entreprise dans SON contexte (paramètres, rubrique de base, réglages) et crée
 * son administrateur. Aucun paiement n'est géré ici : l'offre est une donnée déclarative.
 */
@Service
public class EntrepriseService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(EntrepriseService.class);

    public static final Set<String> OFFRES = Set.of("ESSAI", "ESSENTIEL", "PRO", "SUR_MESURE");

    private final EntrepriseRepository entrepriseRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final ParametreRhRepository parametreRhRepository;
    private final RubriquePaieRepository rubriquePaieRepository;
    private final AppSettingRepository appSettingRepository;
    private final PasswordEncoder passwordEncoder;
    private final TransactionTemplate tx;

    public EntrepriseService(EntrepriseRepository entrepriseRepository, UtilisateurRepository utilisateurRepository,
                             ParametreRhRepository parametreRhRepository, RubriquePaieRepository rubriquePaieRepository,
                             AppSettingRepository appSettingRepository, PasswordEncoder passwordEncoder,
                             TransactionTemplate tx) {
        this.entrepriseRepository = entrepriseRepository;
        this.utilisateurRepository = utilisateurRepository;
        this.parametreRhRepository = parametreRhRepository;
        this.rubriquePaieRepository = rubriquePaieRepository;
        this.appSettingRepository = appSettingRepository;
        this.passwordEncoder = passwordEncoder;
        this.tx = tx;
    }

    public List<Map<String, Object>> lister() {
        return entrepriseRepository.findAllByOrderByIdAsc().stream().map(this::toMap).toList();
    }

    public List<Long> actives() {
        return entrepriseRepository.findByStatutOrderByIdAsc("ACTIVE").stream().map(Entreprise::getId).toList();
    }

    public Entreprise parSlug(String slug) {
        return entrepriseRepository.findBySlug(slug)
            .orElseThrow(() -> new ResourceNotFoundException("Entreprise introuvable."));
    }

    public Entreprise parId(Long id) {
        return entrepriseRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Entreprise introuvable."));
    }

    /**
     * Crée une entreprise et son administrateur. Renvoie le mot de passe temporaire de
     * l'administrateur (affiché une seule fois ; changement obligatoire à la première connexion).
     */
    public Map<String, Object> creer(String nom, String slug, String offre, String adminEmail,
                                     String adminPrenom, String adminNom, String adminPassword) {
        if (nom == null || nom.isBlank()) throw new BusinessException("Le nom est obligatoire.");
        if (slug == null || !slug.matches("^[a-z0-9][a-z0-9-]{1,58}[a-z0-9]$")) {
            throw new BusinessException("Identifiant (slug) invalide : minuscules, chiffres et tirets, 3 à 60 caractères.");
        }
        if (entrepriseRepository.findBySlug(slug).isPresent()) throw new BusinessException("Cet identifiant est déjà utilisé.");
        String o = offre == null || offre.isBlank() ? "ESSAI" : offre;
        if (!OFFRES.contains(o)) throw new BusinessException("Offre attendue : " + OFFRES);
        if (adminEmail == null || !adminEmail.contains("@")) throw new BusinessException("E-mail de l'administrateur invalide.");
        // D2 : un e-mail de connexion = une seule entreprise (vérification sur toutes les entreprises).
        boolean emailPris = TenantContext.systeme(() -> tx.execute(s ->
            utilisateurRepository.findByEmailIgnoreCase(adminEmail.trim()).isPresent()));
        if (emailPris) throw new BusinessException("Cet e-mail est déjà utilisé.");

        Entreprise e = new Entreprise();
        e.setNom(nom.trim());
        e.setSlug(slug);
        e.setOffre(o);
        if ("ESSAI".equals(o)) e.setDateFinEssai(LocalDate.now().plusDays(30));
        Entreprise saved = tx.execute(s -> entrepriseRepository.save(e));

        boolean genere = adminPassword == null || adminPassword.isBlank();
        String password = genere ? PasswordGenerator.temporaryPassword() : adminPassword;
        TenantContext.executer(saved.getId(), () -> tx.executeWithoutResult(s -> {
            initialiserDonnees();
            Utilisateur admin = new Utilisateur();
            admin.setEmail(adminEmail.trim().toLowerCase());
            admin.setPrenom(adminPrenom == null || adminPrenom.isBlank() ? "Admin" : adminPrenom.trim());
            admin.setNom(adminNom == null || adminNom.isBlank() ? nom.trim() : adminNom.trim());
            admin.setRole(Role.ADMIN);
            admin.setActif(true);
            admin.setMotDePasse(passwordEncoder.encode(password));
            admin.setDoitChangerMotDePasse(genere);
            admin.setDateCreation(OffsetDateTime.now());
            utilisateurRepository.save(admin);
        }));

        Map<String, Object> out = toMap(saved);
        out.put("adminEmail", adminEmail.trim().toLowerCase());
        if (genere) out.put("motDePasseTemporaire", password);
        return out;
    }

    public Map<String, Object> changerStatut(Long id, String statut) {
        if (!"ACTIVE".equals(statut) && !"SUSPENDUE".equals(statut)) {
            throw new BusinessException("Statut attendu : ACTIVE ou SUSPENDUE.");
        }
        if (id == 1L && "SUSPENDUE".equals(statut)) {
            throw new BusinessException("L'entreprise principale (plateforme) ne peut pas être suspendue.");
        }
        Entreprise e = parId(id);
        e.setStatut(statut);
        return toMap(tx.execute(s -> entrepriseRepository.save(e)));
    }

    public Map<String, Object> changerOffre(Long id, String offre) {
        return changerOffre(id, offre, null);
    }

    /**
     * Change l'offre (déclarative : aucune facturation). L'offre ESSAI exige une date de fin d'essai
     * (30 jours par défaut) ; les autres offres n'en ont pas.
     */
    public Map<String, Object> changerOffre(Long id, String offre, String dateFinEssai) {
        if (!OFFRES.contains(offre)) throw new BusinessException("Offre attendue : " + OFFRES);
        Entreprise e = parId(id);
        e.setOffre(offre);
        if ("ESSAI".equals(offre)) {
            e.setDateFinEssai(dateFinEssai != null && !dateFinEssai.isBlank()
                ? date(dateFinEssai) : java.time.LocalDate.now().plusDays(30));
        } else {
            e.setDateFinEssai(null);
        }
        log.info("Plateforme : offre de l'entreprise {} -> {}", id, offre);
        return toMap(tx.execute(s -> entrepriseRepository.save(e)));
    }

    /** Fiche d'une entreprise : informations et volumes (comptés dans son propre contexte). */
    public Map<String, Object> detail(Long id) {
        Entreprise e = parId(id);
        Map<String, Object> m = toMap(e);
        m.put("creeLe", e.getCreatedAt() != null ? e.getCreatedAt().toString() : null);
        com.grhmobile.tenant.TenantContext.executer(id, () -> tx.execute(s -> {
            m.put("utilisateurs", utilisateurRepository.count());
            m.put("utilisateursActifs", utilisateurRepository.findAll().stream().filter(u -> u.isActif()).count());
            m.put("administrateurs", utilisateurRepository.findAll().stream()
                .filter(u -> u.getRole() == com.grhmobile.enums.Role.ADMIN)
                .map(u -> u.getEmail()).toList());
            return null;
        }));
        return m;
    }

    /** Informations modifiables : nom et pays. Le slug (adresse publique) reste fixe. */
    public Map<String, Object> modifier(Long id, Map<String, String> body) {
        Entreprise e = parId(id);
        String nom = body.get("nom");
        if (nom != null) {
            if (nom.isBlank() || nom.trim().length() > 200) throw new BusinessException("Nom invalide.");
            e.setNom(nom.trim());
        }
        String pays = body.get("pays");
        if (pays != null) {
            if (!pays.trim().matches("^[A-Z]{2}$")) throw new BusinessException("Pays attendu : code ISO à 2 lettres (ex. TG).");
            e.setPays(pays.trim());
        }
        if (body.containsKey("slug") && !e.getSlug().equals(body.get("slug"))) {
            throw new BusinessException("L'identifiant public (slug) ne peut pas être modifié.");
        }
        log.info("Plateforme : informations de l'entreprise {} modifiées", id);
        return toMap(tx.execute(s -> entrepriseRepository.save(e)));
    }

    private static java.time.LocalDate date(String v) {
        try {
            return java.time.LocalDate.parse(v);
        } catch (Exception ex) {
            throw new BusinessException("Date invalide (format AAAA-MM-JJ).");
        }
    }

    /** Données de départ d'une entreprise (dans son propre contexte). Aucune règle légale. */
    private void initialiserDonnees() {
        param("CONGES_MODE_DECOMPTE", "CALENDAIRES",
            "Décompte des jours de congé : CALENDAIRES, OUVRABLES ou OUVRES. À valider selon le Code du travail applicable.");
        param("CONGES_ACQUISITION_JOURS_PAR_MOIS", null,
            "Jours de congé acquis par mois de travail. Vide = acquisition automatique désactivée. Valeur légale à faire valider.");
        param("HEURES_JOUR_NORMALES", null,
            "Durée normale de travail par jour, en heures. Vide = calcul des heures supplémentaires désactivé. Valeur légale à faire valider.");
        RubriquePaie base = new RubriquePaie();
        base.setCode("SALAIRE_BASE");
        base.setLibelle("Salaire de base");
        base.setType("GAIN");
        base.setOrdre(10);
        base.setFormule("SALAIRE_BASE");
        rubriquePaieRepository.save(base);
        for (String[] kv : new String[][] {{"NOTIFICATIONS", "true"}, {"AUTO_LOGOUT", "true"}}) {
            AppSetting s = new AppSetting();
            s.setKey(kv[0]);
            s.setValue(kv[1]);
            appSettingRepository.save(s);
        }
    }

    private void param(String cle, String valeur, String description) {
        ParametreRh p = new ParametreRh();
        p.setCle(cle);
        p.setValeur(valeur);
        p.setDescription(description);
        parametreRhRepository.save(p);
    }

    private Map<String, Object> toMap(Entreprise e) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", e.getId());
        m.put("nom", e.getNom());
        m.put("slug", e.getSlug());
        m.put("statut", e.getStatut());
        m.put("offre", e.getOffre());
        m.put("dateFinEssai", e.getDateFinEssai() != null ? e.getDateFinEssai().toString() : null);
        m.put("pays", e.getPays());
        return m;
    }
}
