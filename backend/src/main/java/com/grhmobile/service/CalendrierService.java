package com.grhmobile.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import com.grhmobile.audit.Auditable;
import com.grhmobile.entity.JourFerie;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.JourFerieRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Jours fériés de l'entreprise et décompte des jours de congé selon le mode paramétré. */
@Service
public class CalendrierService {

    private final JourFerieRepository jourFerieRepository;
    private final ParametresRhService parametresRhService;

    public CalendrierService(JourFerieRepository jourFerieRepository, ParametresRhService parametresRhService) {
        this.jourFerieRepository = jourFerieRepository;
        this.parametresRhService = parametresRhService;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> listFeries() {
        return jourFerieRepository.findAllByOrderByDateAsc().stream()
            .map(j -> Map.<String, Object>of("id", j.getId(), "date", j.getDate().toString(), "libelle", j.getLibelle()))
            .toList();
    }

    @Auditable(action = "CREATE_JOUR_FERIE", entite = "JourFerie")
    @Transactional
    public Map<String, Object> addFerie(LocalDate date, String libelle) {
        if (date == null || libelle == null || libelle.isBlank()) {
            throw new BusinessException("La date et le libellé sont obligatoires.");
        }
        if (jourFerieRepository.existsByDate(date)) {
            throw new BusinessException("Un jour férié existe déjà à cette date.");
        }
        JourFerie j = new JourFerie();
        j.setDate(date);
        j.setLibelle(libelle.trim());
        jourFerieRepository.save(j);
        return Map.of("id", j.getId(), "date", j.getDate().toString(), "libelle", j.getLibelle());
    }

    @Auditable(action = "DELETE_JOUR_FERIE", entite = "JourFerie")
    @Transactional
    public void deleteFerie(Long id) {
        JourFerie j = jourFerieRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Jour férié introuvable."));
        jourFerieRepository.delete(j);
    }

    /**
     * Nombre de jours décomptés entre deux dates incluses.
     * CALENDAIRES : tous les jours ; OUVRABLES : lundi-samedi hors fériés ; OUVRES : lundi-vendredi hors fériés.
     */
    @Transactional(readOnly = true)
    public int compterJoursConge(LocalDate debut, LocalDate fin) {
        if (fin.isBefore(debut)) {
            throw new BusinessException("La date de fin doit être postérieure ou égale à la date de début.");
        }
        String mode = parametresRhService.modeDecompte();
        if ("CALENDAIRES".equals(mode)) {
            return (int) (java.time.temporal.ChronoUnit.DAYS.between(debut, fin) + 1);
        }
        Set<LocalDate> feries = jourFerieRepository.findByDateBetween(debut, fin).stream()
            .map(JourFerie::getDate).collect(Collectors.toSet());
        int jours = 0;
        for (LocalDate d = debut; !d.isAfter(fin); d = d.plusDays(1)) {
            DayOfWeek dow = d.getDayOfWeek();
            boolean travaille = "OUVRABLES".equals(mode) ? dow != DayOfWeek.SUNDAY
                : dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY;
            if (travaille && !feries.contains(d)) {
                jours++;
            }
        }
        return jours;
    }
}
