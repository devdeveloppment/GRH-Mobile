package com.grhmobile.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

import com.grhmobile.entity.Employe;
import com.grhmobile.entity.ParametrePaie;
import com.grhmobile.entity.RubriquePaie;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.repository.ParametrePaieRepository;
import com.grhmobile.repository.RubriquePaieRepository;
import com.grhmobile.util.FormuleEvaluator;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calcul d'un bulletin à partir des rubriques actives et des paramètres en vigueur.
 *
 * <p>Variables disponibles dans les formules : {@code SALAIRE_BASE}, {@code BRUT} (somme des gains
 * déjà calculés), {@code HEURES_SUP} (heures supplémentaires de la période), les codes des paramètres
 * en vigueur au 1er jour de la période, et les codes des rubriques déjà évaluées.
 *
 * <p>Un bulletin n'est « conforme » que si au moins une rubrique de retenue légale existe et que tous
 * les paramètres utilisés sont validés (source + validateur). Sinon il porte un avertissement.
 */
@Service
public class PaieMoteurService {

    public static final String AVERTISSEMENT_NON_VALIDE =
        "SIMULATION : règles de paie non validées par un expert-comptable. Ne constitue pas un bulletin légal.";

    private final RubriquePaieRepository rubriqueRepository;
    private final ParametrePaieRepository parametreRepository;
    private final HeuresSupplementairesService heuresSupService;

    public PaieMoteurService(RubriquePaieRepository rubriqueRepository,
                             ParametrePaieRepository parametreRepository,
                             HeuresSupplementairesService heuresSupService) {
        this.rubriqueRepository = rubriqueRepository;
        this.parametreRepository = parametreRepository;
        this.heuresSupService = heuresSupService;
    }

    public record Ligne(String code, String libelle, String type, int ordre, BigDecimal montant,
                        String formule, String parametresUtilises) {}

    public record Calcul(List<Ligne> lignes, BigDecimal brut, BigDecimal cotisations, BigDecimal impots,
                         BigDecimal autresRetenues, BigDecimal indemnites, BigDecimal net,
                         boolean conforme, String avertissement) {}

    @Transactional(readOnly = true)
    public Calcul calculer(Employe employe, YearMonth periode) {
        LocalDate reference = periode.atDay(1);
        Map<String, BigDecimal> variables = new HashMap<>();
        Map<String, ParametrePaie> parametres = new HashMap<>();
        for (ParametrePaie p : parametreRepository.findAll()) {
            if (p.couvre(reference)) {
                ParametrePaie existing = parametres.get(p.getCode());
                if (existing == null || p.getDateDebut().isAfter(existing.getDateDebut())) {
                    parametres.put(p.getCode(), p);
                }
            }
        }
        parametres.forEach((code, p) -> variables.put(code, p.getValeur()));
        variables.put("SALAIRE_BASE", employe.getSalaireBrutBase() != null ? employe.getSalaireBrutBase() : BigDecimal.ZERO);
        variables.put("HEURES_SUP", heuresSupService.heuresSupplementaires(employe, periode));

        List<RubriquePaie> rubriques = rubriqueRepository.findByActifTrueOrderByOrdreAsc();
        if (rubriques.isEmpty()) {
            throw new BusinessException("Aucune rubrique de paie active.");
        }

        List<Ligne> lignes = new ArrayList<>();
        BigDecimal brut = BigDecimal.ZERO;
        BigDecimal cotisations = BigDecimal.ZERO;
        BigDecimal impots = BigDecimal.ZERO;
        BigDecimal autres = BigDecimal.ZERO;
        BigDecimal indemnites = BigDecimal.ZERO;
        boolean parametresTousValides = true;
        boolean retenueLegale = false;

        for (RubriquePaie r : rubriques) {
            variables.put("BRUT", brut);
            FormuleEvaluator.Resultat res;
            try {
                res = FormuleEvaluator.evaluer(r.getFormule(), variables);
            } catch (IllegalArgumentException e) {
                throw new BusinessException("Rubrique " + r.getCode() + " : " + e.getMessage());
            }
            BigDecimal montant = res.valeur().setScale(2, RoundingMode.HALF_UP);
            TreeSet<String> paramsUtilises = new TreeSet<>();
            for (String v : res.variablesUtilisees()) {
                ParametrePaie p = parametres.get(v);
                if (p != null) {
                    paramsUtilises.add(v + "=" + p.getValeur().stripTrailingZeros().toPlainString()
                        + (p.estValide() ? " (validé)" : " (NON validé)"));
                    parametresTousValides &= p.estValide();
                }
            }
            // Une retenue légale doit reposer sur un paramètre validé, jamais sur un taux écrit en dur.
            if (("COTISATION_SALARIALE".equals(r.getType()) || "IMPOT".equals(r.getType())) && paramsUtilises.isEmpty()) {
                parametresTousValides = false;
            }
            switch (r.getType()) {
                case "GAIN" -> {
                    brut = brut.add(montant);
                    if (!"SALAIRE_BASE".equals(r.getCode())) {
                        indemnites = indemnites.add(montant);
                    }
                }
                case "COTISATION_SALARIALE" -> { cotisations = cotisations.add(montant); retenueLegale = true; }
                case "IMPOT" -> { impots = impots.add(montant); retenueLegale = true; }
                default -> autres = autres.add(montant);
            }
            variables.put(r.getCode(), montant);
            lignes.add(new Ligne(r.getCode(), r.getLibelle(), r.getType(), r.getOrdre(), montant, r.getFormule(),
                String.join("; ", paramsUtilises)));
        }

        BigDecimal net = brut.subtract(cotisations).subtract(impots).subtract(autres);
        boolean conforme = retenueLegale && parametresTousValides;
        return new Calcul(lignes, brut, cotisations, impots, autres, indemnites, net, conforme,
            conforme ? null : AVERTISSEMENT_NON_VALIDE);
    }
}
