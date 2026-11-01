package com.grhmobile.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import com.grhmobile.entity.ParametreRh;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.ParametreRhRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Paramètres RH de l'entreprise. Les clés sont fixées par la migration V29. */
@Service
public class ParametresRhService {

    public static final String MODE_DECOMPTE = "CONGES_MODE_DECOMPTE";
    public static final String ACQUISITION_JOURS_PAR_MOIS = "CONGES_ACQUISITION_JOURS_PAR_MOIS";
    public static final String HEURES_JOUR_NORMALES = "HEURES_JOUR_NORMALES";

    public static final Set<String> MODES = Set.of("CALENDAIRES", "OUVRABLES", "OUVRES");

    private final ParametreRhRepository repository;

    public ParametresRhService(ParametreRhRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> list() {
        return repository.findAll().stream()
            .sorted((a, b) -> a.getCle().compareTo(b.getCle()))
            .map(p -> {
                Map<String, Object> m = new java.util.LinkedHashMap<>();
                m.put("cle", p.getCle());
                m.put("valeur", p.getValeur());
                m.put("description", p.getDescription());
                return m;
            })
            .toList();
    }

    @Transactional
    public void update(String cle, String valeur) {
        ParametreRh p = repository.findById(cle)
            .orElseThrow(() -> new ResourceNotFoundException("Paramètre inconnu : " + cle));
        String v = valeur == null || valeur.isBlank() ? null : valeur.trim();
        switch (cle) {
            case MODE_DECOMPTE -> {
                if (v == null || !MODES.contains(v)) {
                    throw new BusinessException("Mode de décompte attendu : " + MODES);
                }
            }
            case ACQUISITION_JOURS_PAR_MOIS, HEURES_JOUR_NORMALES -> {
                if (v != null) {
                    try {
                        BigDecimal n = new BigDecimal(v.replace(',', '.'));
                        if (n.signum() <= 0 || n.compareTo(BigDecimal.valueOf(24)) > 0) {
                            throw new BusinessException("Valeur attendue : nombre strictement positif (au plus 24).");
                        }
                        v = n.stripTrailingZeros().toPlainString();
                    } catch (NumberFormatException e) {
                        throw new BusinessException("Valeur numérique attendue pour " + cle + ".");
                    }
                }
            }
            default -> throw new BusinessException("Paramètre non modifiable : " + cle);
        }
        p.setValeur(v);
        repository.save(p);
    }

    @Transactional(readOnly = true)
    public String modeDecompte() {
        return repository.findById(MODE_DECOMPTE).map(ParametreRh::getValeur).filter(MODES::contains).orElse("CALENDAIRES");
    }

    @Transactional(readOnly = true)
    public Optional<BigDecimal> nombre(String cle) {
        return repository.findById(cle)
            .map(ParametreRh::getValeur)
            .filter(v -> v != null && !v.isBlank())
            .map(BigDecimal::new);
    }
}
