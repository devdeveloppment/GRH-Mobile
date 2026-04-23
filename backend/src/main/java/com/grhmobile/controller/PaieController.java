package com.grhmobile.controller;

import java.util.Map;

import com.grhmobile.dto.paie.PayrollPeriodRequest;
import com.grhmobile.service.PaieService;

import jakarta.validation.Valid;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
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

    @GetMapping
    public Map<String, Object> list(
        @RequestParam int month,
        @RequestParam int year
    ) {
        return paieService.listForPeriod(month, year);
    }

    @PostMapping("/calculate")
    public ResponseEntity<Void> calculateAll(@Valid @RequestBody PayrollPeriodRequest request) {
        paieService.calculateAll(request);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/bulletin/pdf")
    public ResponseEntity<byte[]> payslipPdf(@PathVariable Long id) {
        byte[] content = paieService.generatePayslipPdf(id);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename("bulletin-" + id + ".pdf").build().toString())
            .contentType(MediaType.APPLICATION_PDF)
            .body(content);
    }
}
