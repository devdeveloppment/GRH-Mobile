package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.paie.PayrollPeriodRequest;
import com.grhmobile.service.PaieService;

import jakarta.validation.Valid;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/paie")
public class PaieController {

    private final PaieService paieService;

    public PaieController(PaieService paieService) {
        this.paieService = paieService;
    }

    @GetMapping("/me")
    public Map<String, Object> listMine() {
        return paieService.listMine();
    }

    @GetMapping
    @PreAuthorize("@acl.can('MANAGE_PAIE')")
    public Map<String, Object> list(
        @RequestParam int month,
        @RequestParam int year
    ) {
        return paieService.listForPeriod(month, year);
    }

    @PostMapping("/calculate")
    @PreAuthorize("@acl.can('MANAGE_PAIE')")
    public ResponseEntity<Void> calculateAll(@Valid @RequestBody PayrollPeriodRequest request) {
        paieService.calculateAll(request);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/bulletin/pdf")
    @PreAuthorize("@acl.canViewFichePaie(#id)")
    public ResponseEntity<byte[]> payslipPdf(@PathVariable Long id) {
        byte[] content = paieService.generatePayslipPdf(id);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename("bulletin-" + id + ".pdf").build().toString())
            .contentType(MediaType.APPLICATION_PDF)
            .body(content);
    }

    @PreAuthorize("@acl.can('MANAGE_PAIE')")
    @PostMapping("/validate")
    public Map<String, Object> validatePayroll(@Valid @RequestBody PayrollPeriodRequest request) {
        return paieService.validateForPeriod(request);
    }

    @PreAuthorize("@acl.can('MANAGE_PAIE')")
    @GetMapping("/export/csv")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam int month,
            @RequestParam int year) {
        byte[] content = paieService.exportCsv(month, year);
        String filename = "paie-" + year + "-" + String.format("%02d", month) + ".csv";
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename(filename).build().toString())
            .contentType(MediaType.parseMediaType("text/csv;charset=UTF-8"))
            .body(content);
    }
}
