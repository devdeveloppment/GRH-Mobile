package com.grhmobile.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;

import com.grhmobile.dto.dashboard.DashboardSummaryResponse;
import com.grhmobile.dto.paie.FichePaieResponse;
import com.grhmobile.dto.report.GenerateReportRequest;
import com.grhmobile.dto.report.ReportExport;
import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Presence;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PresenceRepository;

import com.lowagie.text.Document;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfWriter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReportService {

    private static final DateTimeFormatter PERIOD_FMT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final DashboardService dashboardService;
    private final PaieService paieService;
    private final PresenceRepository presenceRepository;
    private final CongeRepository congeRepository;
    private final FichePaieRepository fichePaieRepository;
    private final EmployeRepository employeRepository;

    public ReportService(
            DashboardService dashboardService,
            PaieService paieService,
            PresenceRepository presenceRepository,
            CongeRepository congeRepository,
            FichePaieRepository fichePaieRepository,
            EmployeRepository employeRepository) {
        this.dashboardService = dashboardService;
        this.paieService = paieService;
        this.presenceRepository = presenceRepository;
        this.congeRepository = congeRepository;
        this.fichePaieRepository = fichePaieRepository;
        this.employeRepository = employeRepository;
    }

    public ReportExport export(String format) {
        return switch (format.toLowerCase()) {
            case "excel", "xlsx" -> exportExcel();
            default -> exportPdf();
        };
    }

    private ReportExport exportPdf() {
        DashboardSummaryResponse summary = dashboardService.getSummary();
        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Document document = new Document();
            PdfWriter.getInstance(document, outputStream);
            document.open();
            document.add(new Paragraph("GRH-Mobile - Rapport Direction", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18)));
            document.add(new Paragraph(" "));
            document.add(new Paragraph("Effectif total: " + summary.totalEmployees()));
            document.add(new Paragraph("Présents aujourd'hui: " + summary.presentToday()));
            document.add(new Paragraph("Congés en attente: " + summary.pendingLeaves()));
            document.add(new Paragraph("Masse salariale: " + summary.payrollMass() + " FCFA"));
            document.add(new Paragraph("Taux de présence: " + summary.attendanceRate() + "%"));
            document.add(new Paragraph("Turnover: " + summary.turnoverRate() + "%"));
            document.close();
            return new ReportExport(outputStream.toByteArray(), "rapport-grh-mobile.pdf", "application/pdf");
        } catch (Exception exception) {
            throw new IllegalStateException("La génération du rapport PDF a échoué.", exception);
        }
    }

    private ReportExport exportExcel() {
        DashboardSummaryResponse summary = dashboardService.getSummary();
        List<FichePaieResponse> payroll = (List<FichePaieResponse>) paieService
            .listForPeriod(java.time.YearMonth.now().getMonthValue(), java.time.YearMonth.now().getYear())
            .get("items");

        try (XSSFWorkbook workbook = new XSSFWorkbook(); ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            XSSFSheet overview = workbook.createSheet("Vue RH");
            Row row0 = overview.createRow(0);
            row0.createCell(0).setCellValue("Indicateur");
            row0.createCell(1).setCellValue("Valeur");
            writeMetric(overview, 1, "Effectif total", summary.totalEmployees());
            writeMetric(overview, 2, "Présents aujourd'hui", summary.presentToday());
            writeMetric(overview, 3, "Congés en attente", summary.pendingLeaves());
            writeMetric(overview, 4, "Masse salariale", summary.payrollMass());
            writeMetric(overview, 5, "Taux de présence", summary.attendanceRate());

            XSSFSheet payrollSheet = workbook.createSheet("Paie");
            Row header = payrollSheet.createRow(0);
            header.createCell(0).setCellValue("Employé");
            header.createCell(1).setCellValue("Période");
            header.createCell(2).setCellValue("Salaire brut");
            header.createCell(3).setCellValue("CNSS");
            header.createCell(4).setCellValue("Impôts");
            header.createCell(5).setCellValue("Indemnités");
            header.createCell(6).setCellValue("Salaire net");

            for (int index = 0; index < payroll.size(); index++) {
                FichePaieResponse item = payroll.get(index);
                Row row = payrollSheet.createRow(index + 1);
                row.createCell(0).setCellValue(item.nomEmploye());
                row.createCell(1).setCellValue(item.periode());
                row.createCell(2).setCellValue(item.salaireBrut());
                row.createCell(3).setCellValue(item.cotisations());
                row.createCell(4).setCellValue(item.impots());
                row.createCell(5).setCellValue(item.indemnites());
                row.createCell(6).setCellValue(item.salaireNet());
            }

            workbook.write(outputStream);
            return new ReportExport(
                outputStream.toByteArray(),
                "rapport-grh-mobile.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            );
        } catch (IOException exception) {
            throw new IllegalStateException("La génération du rapport Excel a échoué.", exception);
        }
    }

    // ── Génération personnalisée ─────────────────────────────────────────────

    @Transactional(readOnly = true)
    public ReportExport generateReport(GenerateReportRequest req) {
        String type = req.type() != null ? req.type().toUpperCase() : "";
        String format = req.format() != null ? req.format().toUpperCase() : "PDF";
        return switch (type) {
            case "PRESENCES" -> presencesReport(req, format);
            case "CONGES"    -> congesReport(req, format);
            case "PAIE"      -> paieReport(req, format);
            case "EFFECTIFS" -> effectifsReport(req, format);
            default -> throw new IllegalArgumentException("Type inconnu : " + type);
        };
    }

    private ReportExport presencesReport(GenerateReportRequest req, String format) {
        LocalDate debut = req.debut() != null ? req.debut() : LocalDate.now().withDayOfMonth(1);
        LocalDate fin   = req.fin()   != null ? req.fin()   : LocalDate.now();
        List<Presence> data = presenceRepository.findByDateBetweenOrderByDateAsc(debut, fin);
        if (req.service() != null && !req.service().isBlank()) {
            data = data.stream()
                .filter(p -> req.service().equalsIgnoreCase(serviceName(p.getEmploye())))
                .toList();
        }
        String basename = "presences-" + debut + "-" + fin;
        if ("CSV".equals(format)) {
            StringBuilder sb = new StringBuilder("matricule,nom,prenom,service,date,statut\n");
            for (Presence p : data) {
                Employe e = p.getEmploye();
                sb.append(csv(e.getMatricule())).append(',')
                  .append(csv(e.getNom())).append(',')
                  .append(csv(e.getPrenom())).append(',')
                  .append(csv(serviceName(e))).append(',')
                  .append(p.getDate()).append(',')
                  .append(p.getStatut() != null ? p.getStatut().name() : "").append('\n');
            }
            return new ReportExport(sb.toString().getBytes(StandardCharsets.UTF_8), basename + ".csv", "text/csv;charset=UTF-8");
        }
        return presencesPdf(data, debut, fin, basename);
    }

    private ReportExport congesReport(GenerateReportRequest req, String format) {
        LocalDate debut = req.debut() != null ? req.debut() : LocalDate.now().withDayOfMonth(1);
        LocalDate fin   = req.fin()   != null ? req.fin()   : LocalDate.now();
        List<Conge> data = congeRepository.findByDateDebutBetweenOrderByDateDebutAsc(debut, fin);
        if (req.service() != null && !req.service().isBlank()) {
            data = data.stream()
                .filter(c -> req.service().equalsIgnoreCase(serviceName(c.getEmploye())))
                .toList();
        }
        String basename = "conges-" + debut + "-" + fin;
        if ("CSV".equals(format)) {
            StringBuilder sb = new StringBuilder("matricule,nom,prenom,service,date_debut,date_fin,type,statut\n");
            for (Conge c : data) {
                Employe e = c.getEmploye();
                sb.append(csv(e.getMatricule())).append(',')
                  .append(csv(e.getNom())).append(',')
                  .append(csv(e.getPrenom())).append(',')
                  .append(csv(serviceName(e))).append(',')
                  .append(c.getDateDebut()).append(',')
                  .append(c.getDateFin()).append(',')
                  .append(c.getTypeConge() != null ? c.getTypeConge().name() : "").append(',')
                  .append(c.getStatut() != null ? c.getStatut().name() : "").append('\n');
            }
            return new ReportExport(sb.toString().getBytes(StandardCharsets.UTF_8), basename + ".csv", "text/csv;charset=UTF-8");
        }
        return congesPdf(data, debut, fin, basename);
    }

    private ReportExport paieReport(GenerateReportRequest req, String format) {
        LocalDate debut = req.debut() != null ? req.debut() : LocalDate.now().withDayOfMonth(1);
        LocalDate fin   = req.fin()   != null ? req.fin()   : LocalDate.now();
        String debutPeriod = YearMonth.from(debut).format(PERIOD_FMT);
        String finPeriod   = YearMonth.from(fin).format(PERIOD_FMT);
        List<FichePaie> data = fichePaieRepository.findByPeriodeBetweenOrderByPeriodeAscEmployeNomAsc(debutPeriod, finPeriod);
        if (req.service() != null && !req.service().isBlank()) {
            data = data.stream()
                .filter(f -> req.service().equalsIgnoreCase(serviceName(f.getEmploye())))
                .toList();
        }
        String basename = "paie-" + debutPeriod + "-" + finPeriod;
        if ("CSV".equals(format)) {
            StringBuilder sb = new StringBuilder("matricule,nom,prenom,service,periode,salaire_base,primes,deductions,net_a_payer\n");
            for (FichePaie f : data) {
                Employe e = f.getEmploye();
                sb.append(csv(e.getMatricule())).append(',')
                  .append(csv(e.getNom())).append(',')
                  .append(csv(e.getPrenom())).append(',')
                  .append(csv(serviceName(e))).append(',')
                  .append(f.getPeriode()).append(',')
                  .append(f.getSalaireBrut()).append(',')
                  .append(f.getIndemnites()).append(',')
                  .append(f.getCotisations().add(f.getImpots())).append(',')
                  .append(f.getSalaireNet()).append('\n');
            }
            return new ReportExport(sb.toString().getBytes(StandardCharsets.UTF_8), basename + ".csv", "text/csv;charset=UTF-8");
        }
        return paiePdf(data, debutPeriod, finPeriod, basename);
    }

    private ReportExport effectifsReport(GenerateReportRequest req, String format) {
        List<Employe> data = employeRepository.findAll();
        if (req.service() != null && !req.service().isBlank()) {
            data = data.stream()
                .filter(e -> req.service().equalsIgnoreCase(serviceName(e)))
                .toList();
        }
        String basename = "effectifs-" + LocalDate.now();
        if ("CSV".equals(format)) {
            StringBuilder sb = new StringBuilder("matricule,nom,prenom,service,poste,statut\n");
            for (Employe e : data) {
                sb.append(csv(e.getMatricule())).append(',')
                  .append(csv(e.getNom())).append(',')
                  .append(csv(e.getPrenom())).append(',')
                  .append(csv(serviceName(e))).append(',')
                  .append(csv(e.getPoste())).append(',')
                  .append(csv(e.getStatut())).append('\n');
            }
            return new ReportExport(sb.toString().getBytes(StandardCharsets.UTF_8), basename + ".csv", "text/csv;charset=UTF-8");
        }
        return effectifsPdf(data, basename);
    }

    // ── PDF helpers ──────────────────────────────────────────────────────────

    private ReportExport presencesPdf(List<Presence> data, LocalDate debut, LocalDate fin, String basename) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document();
            PdfWriter.getInstance(doc, out);
            doc.open();
            doc.add(new Paragraph("GRH-Mobile — Rapport Présences", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            doc.add(new Paragraph("Période : " + debut + " → " + fin));
            doc.add(new Paragraph("Nombre d'enregistrements : " + data.size()));
            doc.add(new Paragraph(" "));
            for (Presence p : data) {
                Employe e = p.getEmploye();
                doc.add(new Paragraph(e.getPrenom() + " " + e.getNom()
                    + " | " + p.getDate()
                    + " | " + (p.getStatut() != null ? p.getStatut().name() : "-")));
            }
            doc.close();
            return new ReportExport(out.toByteArray(), basename + ".pdf", "application/pdf");
        } catch (Exception ex) {
            throw new IllegalStateException("Génération PDF présences échouée.", ex);
        }
    }

    private ReportExport congesPdf(List<Conge> data, LocalDate debut, LocalDate fin, String basename) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document();
            PdfWriter.getInstance(doc, out);
            doc.open();
            doc.add(new Paragraph("GRH-Mobile — Rapport Congés", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            doc.add(new Paragraph("Période : " + debut + " → " + fin));
            doc.add(new Paragraph("Nombre de congés : " + data.size()));
            doc.add(new Paragraph(" "));
            for (Conge c : data) {
                Employe e = c.getEmploye();
                doc.add(new Paragraph(e.getPrenom() + " " + e.getNom()
                    + " | " + c.getDateDebut() + " → " + c.getDateFin()
                    + " | " + (c.getTypeConge() != null ? c.getTypeConge().name() : "-")
                    + " | " + (c.getStatut() != null ? c.getStatut().name() : "-")));
            }
            doc.close();
            return new ReportExport(out.toByteArray(), basename + ".pdf", "application/pdf");
        } catch (Exception ex) {
            throw new IllegalStateException("Génération PDF congés échouée.", ex);
        }
    }

    private ReportExport paiePdf(List<FichePaie> data, String debutPeriod, String finPeriod, String basename) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document();
            PdfWriter.getInstance(doc, out);
            doc.open();
            doc.add(new Paragraph("GRH-Mobile — Rapport Paie", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            doc.add(new Paragraph("Périodes : " + debutPeriod + " → " + finPeriod));
            doc.add(new Paragraph("Nombre de bulletins : " + data.size()));
            doc.add(new Paragraph(" "));
            for (FichePaie f : data) {
                Employe e = f.getEmploye();
                doc.add(new Paragraph(e.getPrenom() + " " + e.getNom()
                    + " | " + f.getPeriode()
                    + " | Brut : " + f.getSalaireBrut()
                    + " | Net : " + f.getSalaireNet()));
            }
            doc.close();
            return new ReportExport(out.toByteArray(), basename + ".pdf", "application/pdf");
        } catch (Exception ex) {
            throw new IllegalStateException("Génération PDF paie échouée.", ex);
        }
    }

    private ReportExport effectifsPdf(List<Employe> data, String basename) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document();
            PdfWriter.getInstance(doc, out);
            doc.open();
            doc.add(new Paragraph("GRH-Mobile — Rapport Effectifs", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
            doc.add(new Paragraph("Effectif total : " + data.size()));
            doc.add(new Paragraph(" "));
            for (Employe e : data) {
                doc.add(new Paragraph(e.getMatricule()
                    + " | " + e.getPrenom() + " " + e.getNom()
                    + " | " + csv(e.getPoste())
                    + " | " + serviceName(e)
                    + " | " + csv(e.getStatut())));
            }
            doc.close();
            return new ReportExport(out.toByteArray(), basename + ".pdf", "application/pdf");
        } catch (Exception ex) {
            throw new IllegalStateException("Génération PDF effectifs échouée.", ex);
        }
    }

    // ── Utils ────────────────────────────────────────────────────────────────

    private String serviceName(Employe e) {
        return e.getService() != null ? e.getService().getNom() : "";
    }

    private String csv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    private void writeMetric(XSSFSheet sheet, int rowIndex, String label, double value) {
        Row row = sheet.createRow(rowIndex);
        row.createCell(0).setCellValue(label);
        row.createCell(1).setCellValue(value);
    }
}
