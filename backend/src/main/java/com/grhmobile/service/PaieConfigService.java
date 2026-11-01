package com.grhmobile.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.grhmobile.audit.Auditable;
import com.grhmobile.entity.LigneBulletin;
import com.grhmobile.entity.ParametrePaie;
import com.grhmobile.entity.RubriquePaie;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.LigneBulletinRepository;
import com.grhmobile.repository.ParametrePaieRepository;
import com.grhmobile.repository.RubriquePaieRepository;
import com.grhmobile.util.FormuleEvaluator;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Gestion des rubriques et des paramètres de paie. Un paramètre n'est jamais supprimé ni
 * modifié en valeur : on crée une nouvelle version datée (historisation). Seule la validation
 * (source + validateur) peut être complétée a posteriori.
 */
@Service
public class PaieConfigService {

    private static final String CODE = "[A-Z][A-Z0-9_]*";

    private final RubriquePaieRepository rubriqueRepository;
    private final ParametrePaieRepository parametreRepository;
    private final LigneBulletinRepository ligneRepository;
    private final FichePaieRepository fichePaieRepository;

    public PaieConfigService(RubriquePaieRepository rubriqueRepository, ParametrePaieRepository parametreRepository,
                             LigneBulletinRepository ligneRepository, FichePaieRepository fichePaieRepository) {
        this.rubriqueRepository = rubriqueRepository;
        this.parametreRepository = parametreRepository;
        this.ligneRepository = ligneRepository;
        this.fichePaieRepository = fichePaieRepository;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listRubriques() {
        List<Map<String, Object>> items = rubriqueRepository.findAllByOrderByOrdreAsc().stream().map(this::toMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    @Auditable(action = "SAVE_RUBRIQUE_PAIE", entite = "RubriquePaie")
    @Transactional
    public Map<String, Object> saveRubrique(Long id, Map<String, Object> body) {
        RubriquePaie r = id == null ? new RubriquePaie()
            : rubriqueRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Rubrique introuvable."));
        String code = str(body, "code");
        String type = str(body, "type");
        String formule = str(body, "formule");
        if (id == null) {
            if (code == null || !code.matches(CODE)) {
                throw new BusinessException("Code invalide (majuscules, chiffres et _).");
            }
            if (rubriqueRepository.findByCode(code).isPresent()) {
                throw new BusinessException("Une rubrique porte déjà ce code.");
            }
            r.setCode(code);
        }
        if (str(body, "libelle") != null) r.setLibelle(str(body, "libelle"));
        if (type != null) {
            if (!RubriquePaie.TYPES.contains(type)) {
                throw new BusinessException("Type attendu : " + RubriquePaie.TYPES);
            }
            r.setType(type);
        }
        if (body.get("ordre") != null) r.setOrdre(((Number) body.get("ordre")).intValue());
        if (formule != null) {
            verifierSyntaxe(formule);
            r.setFormule(formule);
        }
        if (body.get("actif") != null) r.setActif(Boolean.TRUE.equals(body.get("actif")));
        if (r.getLibelle() == null || r.getType() == null || r.getFormule() == null) {
            throw new BusinessException("Libellé, type et formule sont obligatoires.");
        }
        rubriqueRepository.save(r);
        return toMap(r);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listParametres() {
        List<Map<String, Object>> items = parametreRepository.findAllByOrderByCodeAscDateDebutDesc().stream()
            .map(this::toMap).toList();
        return Map.of("items", items, "total", items.size(),
            "avertissement", "Aucun paramètre légal n'est fourni : chaque valeur doit provenir d'une source officielle et être validée.");
    }

    @Auditable(action = "CREATE_PARAMETRE_PAIE", entite = "ParametrePaie")
    @Transactional
    public Map<String, Object> createParametre(Map<String, Object> body) {
        String code = str(body, "code");
        if (code == null || !code.matches(CODE) || List.of("SALAIRE_BASE", "BRUT", "HEURES_SUP").contains(code)) {
            throw new BusinessException("Code invalide ou réservé.");
        }
        ParametrePaie p = new ParametrePaie();
        p.setCode(code);
        p.setLibelle(required(body, "libelle"));
        try {
            p.setValeur(new BigDecimal(String.valueOf(body.get("valeur")).replace(',', '.')));
            p.setDateDebut(LocalDate.parse(required(body, "dateDebut")));
            if (str(body, "dateFin") != null) p.setDateFin(LocalDate.parse(str(body, "dateFin")));
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("Valeur ou dates invalides.");
        }
        if (p.getDateFin() != null && p.getDateFin().isBefore(p.getDateDebut())) {
            throw new BusinessException("La date de fin doit suivre la date de début.");
        }
        p.setSource(str(body, "source"));
        p.setEnregistrePar(utilisateurCourant());
        parametreRepository.save(p);
        return toMap(p);
    }

    /** Soumet un paramètre en brouillon à la validation d'un expert (source obligatoire). */
    @Auditable(action = "SUBMIT_PARAMETRE_PAIE", entite = "ParametrePaie")
    @Transactional
    public Map<String, Object> soumettreParametre(Long id, Map<String, Object> body) {
        ParametrePaie p = parametreRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Paramètre introuvable."));
        if (!"BROUILLON".equals(p.getStatut())) {
            throw new BusinessException("Seul un paramètre en brouillon peut être soumis.");
        }
        if (str(body, "source") != null) {
            p.setSource(str(body, "source"));
        }
        if (p.getSource() == null) {
            throw new BusinessException("Indiquez la source officielle (texte, article, date de publication).");
        }
        p.setStatut("SOUMIS");
        p.setSoumisPar(utilisateurCourant());
        p.setDateSoumission(java.time.OffsetDateTime.now());
        parametreRepository.save(p);
        return toMap(p);
    }

    @Auditable(action = "VALIDATE_PARAMETRE_PAIE", entite = "ParametrePaie")
    @Transactional
    public Map<String, Object> validerParametre(Long id, Map<String, Object> body) {
        ParametrePaie p = parametreRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Paramètre introuvable."));
        if (!"SOUMIS".equals(p.getStatut())) {
            throw new BusinessException("Le paramètre doit d'abord être soumis à validation.");
        }
        Long courant = utilisateurCourant();
        if (courant != null && courant.equals(p.getSoumisPar())) {
            throw new BusinessException("La validation doit être enregistrée par une autre personne que celle qui a soumis le paramètre.");
        }
        String qualite = required(body, "qualiteValidateur").toUpperCase(java.util.Locale.ROOT);
        if (!List.of("EXPERT_COMPTABLE", "JURISTE", "AUTRE").contains(qualite)) {
            throw new BusinessException("Qualité du validateur invalide.");
        }
        p.setSource(required(body, "source"));
        p.setValidePar(required(body, "validePar"));
        p.setQualiteValidateur(qualite);
        p.setDateValidation(LocalDate.now());
        p.setStatut("VALIDE");
        parametreRepository.save(p);
        return toMap(p);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> lignes(Long ficheId) {
        if (!fichePaieRepository.existsById(ficheId)) {
            throw new ResourceNotFoundException("Fiche de paie introuvable.");
        }
        List<Map<String, Object>> items = ligneRepository.findByFichePaieIdOrderByOrdreAsc(ficheId).stream()
            .map(this::toMap).toList();
        return Map.of("items", items, "total", items.size());
    }

    private void verifierSyntaxe(String formule) {
        Map<String, BigDecimal> fake = new java.util.HashMap<>();
        for (String v : FormuleEvaluator.variablesReferencees(formule)) {
            fake.put(v, BigDecimal.ONE);
        }
        try {
            FormuleEvaluator.evaluer(formule, fake);
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Formule invalide : " + e.getMessage());
        }
    }

    private Map<String, Object> toMap(RubriquePaie r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("code", r.getCode());
        m.put("libelle", r.getLibelle());
        m.put("type", r.getType());
        m.put("ordre", r.getOrdre());
        m.put("formule", r.getFormule());
        m.put("actif", r.isActif());
        return m;
    }

    private Map<String, Object> toMap(ParametrePaie p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("code", p.getCode());
        m.put("libelle", p.getLibelle());
        m.put("valeur", p.getValeur());
        m.put("dateDebut", p.getDateDebut().toString());
        m.put("dateFin", p.getDateFin() != null ? p.getDateFin().toString() : null);
        m.put("source", p.getSource());
        m.put("validePar", p.getValidePar());
        m.put("valide", p.estValide());
        m.put("statut", p.getStatut());
        m.put("qualiteValidateur", p.getQualiteValidateur());
        m.put("dateValidation", p.getDateValidation() != null ? p.getDateValidation().toString() : null);
        m.put("dateSoumission", p.getDateSoumission() != null ? p.getDateSoumission().toString() : null);
        return m;
    }

    private Map<String, Object> toMap(LigneBulletin l) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", l.getRubriqueCode());
        m.put("libelle", l.getLibelle());
        m.put("type", l.getType());
        m.put("montant", l.getMontant());
        m.put("formule", l.getFormule());
        m.put("parametresUtilises", l.getParametresUtilises());
        return m;
    }

    private Long utilisateurCourant() {
        org.springframework.security.core.Authentication a =
            org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getPrincipal() instanceof com.grhmobile.security.UserPrincipal up
            ? up.getUtilisateur().getId() : null;
    }

    private static String str(Map<String, Object> body, String key) {
        Object v = body.get(key);
        return v == null || String.valueOf(v).isBlank() ? null : String.valueOf(v).trim();
    }

    private static String required(Map<String, Object> body, String key) {
        String v = str(body, key);
        if (v == null) {
            throw new BusinessException("Le champ « " + key + " » est obligatoire.");
        }
        return v;
    }
}
