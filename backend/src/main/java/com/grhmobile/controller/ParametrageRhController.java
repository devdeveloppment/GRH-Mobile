package com.grhmobile.controller;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

import com.grhmobile.exception.BusinessException;
import com.grhmobile.service.AcquisitionCongesService;
import com.grhmobile.service.CalendrierService;
import com.grhmobile.service.HeuresSupplementairesService;
import com.grhmobile.service.ParametresRhService;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/** Paramétrage RH : paramètres, jours fériés, heures supplémentaires, acquisition des congés. */
@RestController
@RequestMapping("/api")
public class ParametrageRhController {

    private final ParametresRhService parametresRhService;
    private final CalendrierService calendrierService;
    private final HeuresSupplementairesService heuresSupService;
    private final AcquisitionCongesService acquisitionService;

    public ParametrageRhController(ParametresRhService parametresRhService, CalendrierService calendrierService,
                                   HeuresSupplementairesService heuresSupService,
                                   AcquisitionCongesService acquisitionService) {
        this.parametresRhService = parametresRhService;
        this.calendrierService = calendrierService;
        this.heuresSupService = heuresSupService;
        this.acquisitionService = acquisitionService;
    }

    @GetMapping("/parametres-rh")
    @PreAuthorize("@acl.can('MANAGE_LEAVES') or @acl.can('MANAGE_PAIE')")
    public Map<String, Object> listParametres() {
        List<Map<String, Object>> items = parametresRhService.list();
        return Map.of("items", items, "total", items.size());
    }

    @PutMapping("/parametres-rh/{cle}")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','HR_ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void updateParametre(@PathVariable String cle, @RequestBody Map<String, String> body) {
        parametresRhService.update(cle, body.get("valeur"));
    }

    /** Lecture ouverte à tout utilisateur connecté (calendrier de l'entreprise). */
    @GetMapping("/jours-feries")
    public Map<String, Object> listFeries() {
        List<Map<String, Object>> items = calendrierService.listFeries();
        return Map.of("items", items, "total", items.size());
    }

    @PostMapping("/jours-feries")
    @PreAuthorize("@acl.can('MANAGE_LEAVES')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addFerie(@RequestBody Map<String, String> body) {
        LocalDate date;
        try {
            date = LocalDate.parse(body.getOrDefault("date", ""));
        } catch (Exception e) {
            throw new BusinessException("Date invalide (format attendu : AAAA-MM-JJ).");
        }
        return calendrierService.addFerie(date, body.get("libelle"));
    }

    @DeleteMapping("/jours-feries/{id}")
    @PreAuthorize("@acl.can('MANAGE_LEAVES')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteFerie(@PathVariable Long id) {
        calendrierService.deleteFerie(id);
    }

    /** Aperçu du nombre de jours décomptés (aide à la saisie d'une demande). */
    @GetMapping("/conges/decompte")
    public Map<String, Object> decompte(
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate debut,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fin) {
        return Map.of("jours", calendrierService.compterJoursConge(debut, fin),
            "mode", parametresRhService.modeDecompte());
    }

    @GetMapping("/presences/heures-supplementaires")
    @PreAuthorize("@acl.can('MANAGE_PAIE') or @acl.can('MANAGE_LEAVES') or hasRole('DIRECTION')")
    public Map<String, Object> heuresSupplementaires(
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate debut,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fin) {
        if (fin.isBefore(debut)) {
            throw new BusinessException("La date de fin doit être postérieure ou égale à la date de début.");
        }
        return heuresSupService.rapport(debut, fin);
    }

    /** Déclenchement manuel (idempotent) de l'acquisition mensuelle des congés. */
    @PostMapping("/conges/acquisitions")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','HR_ADMIN')")
    public Map<String, Object> acquerir(@RequestParam int month, @RequestParam int year) {
        if (month < 1 || month > 12) {
            throw new BusinessException("Mois invalide.");
        }
        return acquisitionService.acquerir(YearMonth.of(year, month));
    }
}
