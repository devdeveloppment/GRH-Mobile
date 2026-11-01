package com.grhmobile.service;

import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import com.grhmobile.entity.AcquisitionConge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.repository.AcquisitionCongeRepository;
import com.grhmobile.repository.EmployeRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Acquisition mensuelle des congés : ajoute CONGES_ACQUISITION_JOURS_PAR_MOIS au solde de chaque
 * employé actif, une seule fois par mois (table acquisitions_conges). Désactivée tant que le
 * paramètre n'est pas renseigné (aucune valeur légale par défaut).
 */
@Service
public class AcquisitionCongesService {

    private static final Logger log = LoggerFactory.getLogger(AcquisitionCongesService.class);

    private final EmployeRepository employeRepository;
    private final AcquisitionCongeRepository acquisitionRepository;
    private final ParametresRhService parametresRhService;
    private final com.grhmobile.repository.EntrepriseRepository entrepriseRepository;

    public AcquisitionCongesService(EmployeRepository employeRepository,
                                    AcquisitionCongeRepository acquisitionRepository,
                                    ParametresRhService parametresRhService,
                                    com.grhmobile.repository.EntrepriseRepository entrepriseRepository) {
        this.entrepriseRepository = entrepriseRepository;
        this.employeRepository = employeRepository;
        this.acquisitionRepository = acquisitionRepository;
        this.parametresRhService = parametresRhService;
    }

    /** Le 1er de chaque mois à 01:00 : acquisition au titre du mois écoulé. */
    @Scheduled(cron = "0 0 1 1 * *")
    public void acquisitionMensuelleAutomatique() {
        for (Long id : entrepriseRepository.findByStatutOrderByIdAsc("ACTIVE").stream().map(e -> e.getId()).toList()) {
            Map<String, Object> r = com.grhmobile.tenant.TenantContext.executer(id, () -> acquerir(YearMonth.now().minusMonths(1)));
            log.info("Acquisition mensuelle des congés (entreprise {}) : {}", id, r);
        }
    }

    @Transactional
    public Map<String, Object> acquerir(YearMonth periode) {
        Map<String, Object> result = new LinkedHashMap<>();
        String key = FichePaie.formatPeriode(periode);
        result.put("periode", key);
        Optional<BigDecimal> jours = parametresRhService.nombre(ParametresRhService.ACQUISITION_JOURS_PAR_MOIS);
        if (jours.isEmpty()) {
            result.put("active", false);
            result.put("message", "Paramètre CONGES_ACQUISITION_JOURS_PAR_MOIS non renseigné : aucune acquisition.");
            result.put("employes", 0);
            return result;
        }
        int count = 0;
        for (Employe e : employeRepository.findAllByStatutIgnoreCase("ACTIF")) {
            if (e.getDateEmbauche() != null && YearMonth.from(e.getDateEmbauche()).isAfter(periode)) {
                continue;
            }
            if (acquisitionRepository.existsByEmployeIdAndPeriode(e.getId(), key)) {
                continue;
            }
            AcquisitionConge a = new AcquisitionConge();
            a.setEmploye(e);
            a.setPeriode(key);
            a.setJours(jours.get());
            acquisitionRepository.save(a);
            BigDecimal solde = e.getSoldeConge() != null ? e.getSoldeConge() : BigDecimal.ZERO;
            e.setSoldeConge(solde.add(jours.get()));
            employeRepository.save(e);
            count++;
        }
        result.put("active", true);
        result.put("joursParMois", jours.get());
        result.put("employes", count);
        return result;
    }
}
