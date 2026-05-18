package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.presence.JustifyAbsenceRequest;
import com.grhmobile.dto.presence.JustifyAbsenceResponse;
import com.grhmobile.dto.presence.PointageRequest;
import com.grhmobile.dto.presence.PointageResponse;
import com.grhmobile.dto.presence.ReportAbsenceRequest;
import com.grhmobile.dto.presence.ReportAbsenceResponse;
import com.grhmobile.dto.qrcode.QrScanRequest;
import com.grhmobile.dto.qrcode.QrScanResponse;
import com.grhmobile.service.PresenceService;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/presences")
public class PresenceController {

    private final PresenceService presenceService;

    public PresenceController(PresenceService presenceService) {
        this.presenceService = presenceService;
    }

    @GetMapping
    public Map<String, Object> list() {
        return presenceService.listAll();
    }

    @GetMapping("/me")
    public Map<String, Object> listMine() {
        return presenceService.listMine();
    }

    @PostMapping("/pointage")
    public PointageResponse pointage(@Valid @RequestBody PointageRequest request) {
        return presenceService.pointage(request);
    }

    @PostMapping("/scan")
    public QrScanResponse scan(@Valid @RequestBody QrScanRequest request) {
        return presenceService.scanPointage(request);
    }

    @PostMapping("/report-absence")
    public ReportAbsenceResponse reportAbsence(@Valid @RequestBody ReportAbsenceRequest request) {
        return presenceService.reportAbsence(request);
    }

    @GetMapping("/absences-en-attente")
    public Map<String, Object> listAbsencesEnAttente() {
        return presenceService.listAbsencesEnAttente();
    }

    @PutMapping("/{id}/justify")
    public JustifyAbsenceResponse justifyAbsence(
        @PathVariable Long id,
        @Valid @RequestBody JustifyAbsenceRequest request
    ) {
        return presenceService.justifyAbsence(id, request);
    }
}
