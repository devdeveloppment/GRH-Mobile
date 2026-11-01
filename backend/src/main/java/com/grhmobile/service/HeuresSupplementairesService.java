package com.grhmobile.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.grhmobile.entity.Employe;
import com.grhmobile.entity.Presence;
import com.grhmobile.repository.PresenceRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Heures supplémentaires = temps de présence journalier au-delà de HEURES_JOUR_NORMALES.
 * Seules les quantités sont calculées : les majorations légales relèvent du moteur de paie
 * (paramètres validés). Si HEURES_JOUR_NORMALES n'est pas renseigné, le calcul est désactivé.
 */
@Service
public class HeuresSupplementairesService {

    private final PresenceRepository presenceRepository;
    private final ParametresRhService parametresRhService;

    public HeuresSupplementairesService(PresenceRepository presenceRepository, ParametresRhService parametresRhService) {
        this.presenceRepository = presenceRepository;
        this.parametresRhService = parametresRhService;
    }

    @Transactional(readOnly = true)
    public BigDecimal heuresSupplementaires(Employe employe, YearMonth periode) {
        Optional<BigDecimal> normales = parametresRhService.nombre(ParametresRhService.HEURES_JOUR_NORMALES);
        if (normales.isEmpty() || employe.getId() == null) {
            return BigDecimal.ZERO;
        }
        return total(presenceRepository.findByEmployeIdOrderByDateDesc(employe.getId()),
            periode.atDay(1), periode.atEndOfMonth(), normales.get());
    }

    /** Rapport par employé sur une période. */
    @Transactional(readOnly = true)
    public Map<String, Object> rapport(LocalDate debut, LocalDate fin) {
        Optional<BigDecimal> normales = parametresRhService.nombre(ParametresRhService.HEURES_JOUR_NORMALES);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("debut", debut.toString());
        result.put("fin", fin.toString());
        result.put("configure", normales.isPresent());
        result.put("heuresJourNormales", normales.map(BigDecimal::toPlainString).orElse(null));
        if (normales.isEmpty()) {
            result.put("items", List.of());
            result.put("message", "Renseignez le paramètre HEURES_JOUR_NORMALES pour activer le calcul.");
            return result;
        }
        Map<Long, List<Presence>> parEmploye = new LinkedHashMap<>();
        for (Presence p : presenceRepository.findByDateBetweenOrderByDateAsc(debut, fin)) {
            parEmploye.computeIfAbsent(p.getEmploye().getId(), k -> new ArrayList<>()).add(p);
        }
        List<Map<String, Object>> items = new ArrayList<>();
        parEmploye.forEach((id, presences) -> {
            Employe e = presences.get(0).getEmploye();
            BigDecimal heures = total(presences, debut, fin, normales.get());
            if (heures.signum() > 0) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("matricule", e.getMatricule());
                m.put("nom", e.getPrenom() + " " + e.getNom());
                m.put("heuresSupplementaires", heures);
                items.add(m);
            }
        });
        result.put("items", items);
        return result;
    }

    static BigDecimal total(List<Presence> presences, LocalDate debut, LocalDate fin, BigDecimal normalesParJour) {
        long minutesNormales = normalesParJour.multiply(BigDecimal.valueOf(60)).longValue();
        long minutesSup = 0;
        for (Presence p : presences) {
            if (p.getDate() == null || p.getDate().isBefore(debut) || p.getDate().isAfter(fin)
                || p.getHeureArrivee() == null || p.getHeureDepart() == null) {
                continue;
            }
            long travaillees = Duration.between(p.getHeureArrivee(), p.getHeureDepart()).toMinutes();
            if (travaillees > minutesNormales) {
                minutesSup += travaillees - minutesNormales;
            }
        }
        return BigDecimal.valueOf(minutesSup).divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP);
    }
}
