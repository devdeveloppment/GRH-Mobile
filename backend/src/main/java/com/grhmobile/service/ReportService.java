package com.grhmobile.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

import com.grhmobile.dto.dashboard.DashboardSummaryResponse;
import com.grhmobile.dto.paie.FichePaieResponse;
import com.grhmobile.dto.report.ReportExport;

import com.lowagie.text.Document;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfWriter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

@Service
public class ReportService {

    private final DashboardService dashboardService;
    private final PaieService paieService;

    public ReportService(DashboardService dashboardService, PaieService paieService) {
        this.dashboardService = dashboardService;
        this.paieService = paieService;
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

    private void writeMetric(XSSFSheet sheet, int rowIndex, String label, double value) {
        Row row = sheet.createRow(rowIndex);
        row.createCell(0).setCellValue(label);
        row.createCell(1).setCellValue(value);
    }
}
