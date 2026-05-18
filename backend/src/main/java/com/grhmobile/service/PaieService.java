package com.grhmobile.service;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import com.grhmobile.dto.paie.FichePaieResponse;
import com.grhmobile.dto.paie.PayrollPeriodRequest;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.exception.ResourceNotFoundException;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;

import com.lowagie.text.Document;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaieService {

    private static final DateTimeFormatter PERIOD_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");

    private final FichePaieRepository fichePaieRepository;
    private final EmployeRepository employeRepository;
    private final NotificationService notificationService;

    public PaieService(FichePaieRepository fichePaieRepository, EmployeRepository employeRepository,
                       NotificationService notificationService) {
        this.fichePaieRepository = fichePaieRepository;
        this.employeRepository = employeRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> listForPeriod(Integer month, Integer year) {
        YearMonth period = YearMonth.of(year, month);
        String key = period.format(PERIOD_FORMATTER);
        List<FichePaieResponse> items = fichePaieRepository.findByPeriodeOrderByEmployeNomAsc(key)
            .stream()
            .map(FichePaieResponse::fromEntity)
            .toList();
        return Map.of("items", items);
    }

    @Transactional
    public void calculateAll(PayrollPeriodRequest request) {
        YearMonth period = YearMonth.of(request.year(), request.month());
        String key = period.format(PERIOD_FORMATTER);
        List<Employe> employees = employeRepository.findAllByStatutIgnoreCase("ACTIF");

        for (Employe employee : employees) {
            FichePaie fichePaie = fichePaieRepository.findByEmployeIdAndPeriode(employee.getId(), key)
                .orElseGet(FichePaie::new);

            BigDecimal gross = employee.getSalaireBrutBase();
            BigDecimal cnss = percent(gross, 4);
            BigDecimal taxes = percent(gross, 8);
            BigDecimal indemnities = percent(gross, 5);
            BigDecimal net = gross.subtract(cnss).subtract(taxes).add(indemnities);

            fichePaie.setEmploye(employee);
            fichePaie.setPeriode(key);
            fichePaie.setSalaireBrut(gross);
            fichePaie.setCotisations(cnss);
            fichePaie.setImpots(taxes);
            fichePaie.setIndemnites(indemnities);
            fichePaie.setSalaireNet(net);
            fichePaie.setCalculee(true);

            fichePaieRepository.save(fichePaie);

            // Notifier l'employé que son bulletin est disponible
            if (employee.getUtilisateur() != null) {
                notificationService.create(
                    employee.getUtilisateur().getId(),
                    "Bulletin de paie disponible",
                    "Votre bulletin de paie pour " + key + " est disponible.",
                    "PAIE",
                    "/rh/paie"
                );
            }
        }
    }

    @Transactional(readOnly = true)
    public List<FichePaieResponse> listByMatricule(String matricule) {
        Employe employe = employeRepository.findByMatricule(matricule)
            .orElseThrow(() -> new ResourceNotFoundException("Employé introuvable."));
        return fichePaieRepository.findByEmployeIdOrderByPeriodeDesc(employe.getId())
            .stream()
            .map(FichePaieResponse::fromEntity)
            .toList();
    }

    @Transactional(readOnly = true)
    public byte[] generatePayslipPdf(Long id) {
        FichePaie fichePaie = fichePaieRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Fiche de paie introuvable."));

        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Document document = new Document();
            PdfWriter.getInstance(document, outputStream);
            document.open();
            document.add(new Paragraph("GRH-Mobile", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18)));
            document.add(new Paragraph("Bulletin de paie - " + fichePaie.getPeriode()));
            document.add(new Paragraph("Employé: " + fichePaie.getEmploye().getPrenom() + " " + fichePaie.getEmploye().getNom()));
            document.add(new Paragraph("Poste: " + fichePaie.getEmploye().getPoste()));
            document.add(new Paragraph(" "));
            document.add(new Paragraph("Salaire brut: " + fichePaie.getSalaireBrut()));
            document.add(new Paragraph("Cotisations CNSS: " + fichePaie.getCotisations()));
            document.add(new Paragraph("Impôts: " + fichePaie.getImpots()));
            document.add(new Paragraph("Indemnités: " + fichePaie.getIndemnites()));
            document.add(new Paragraph("Salaire net: " + fichePaie.getSalaireNet(), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14)));
            document.close();
            return outputStream.toByteArray();
        } catch (Exception exception) {
            throw new IllegalStateException("La génération du PDF a échoué.", exception);
        }
    }

    @Transactional
    public Map<String, Object> validateForPeriod(PayrollPeriodRequest request) {
        YearMonth period = YearMonth.of(request.year(), request.month());
        String key = period.format(PERIOD_FORMATTER);
        List<FichePaie> fiches = fichePaieRepository.findByPeriodeOrderByEmployeNomAsc(key)
            .stream()
            .filter(FichePaie::isCalculee)
            .toList();
        for (FichePaie fiche : fiches) {
            fiche.setValidee(true);
        }
        fichePaieRepository.saveAll(fiches);
        return Map.of("success", true, "mois", key, "nbFiches", fiches.size());
    }

    @Transactional(readOnly = true)
    public byte[] exportCsv(int month, int year) {
        YearMonth period = YearMonth.of(year, month);
        String key = period.format(PERIOD_FORMATTER);
        List<FichePaie> fiches = fichePaieRepository.findByPeriodeOrderByEmployeNomAsc(key);

        StringBuilder sb = new StringBuilder();
        sb.append("matricule,nom,prenom,salaire_base,primes,deductions,net_a_payer\n");
        for (FichePaie fiche : fiches) {
            Employe emp = fiche.getEmploye();
            BigDecimal deductions = fiche.getCotisations().add(fiche.getImpots());
            sb.append(csvEscape(emp.getMatricule())).append(',')
              .append(csvEscape(emp.getNom())).append(',')
              .append(csvEscape(emp.getPrenom())).append(',')
              .append(fiche.getSalaireBrut()).append(',')
              .append(fiche.getIndemnites()).append(',')
              .append(deductions).append(',')
              .append(fiche.getSalaireNet()).append('\n');
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String csvEscape(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    private BigDecimal percent(BigDecimal value, int percent) {
        return value
            .multiply(BigDecimal.valueOf(percent))
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }
}
