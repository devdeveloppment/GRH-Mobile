package com.grhmobile.service;

import com.grhmobile.audit.Auditable;
import com.grhmobile.security.AccessControlService;
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
import com.grhmobile.entity.LigneBulletin;
import com.grhmobile.repository.LigneBulletinRepository;
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
    private final AccessControlService acl;
    private final PaieMoteurService paieMoteurService;
    private final LigneBulletinRepository ligneBulletinRepository;

    public PaieService(FichePaieRepository fichePaieRepository, EmployeRepository employeRepository,
                       NotificationService notificationService, AccessControlService acl,
                       PaieMoteurService paieMoteurService, LigneBulletinRepository ligneBulletinRepository) {
        this.acl = acl;
        this.paieMoteurService = paieMoteurService;
        this.ligneBulletinRepository = ligneBulletinRepository;
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

    @Auditable(action = "CALCULATE_PAYROLL", entite = "FichePaie")
    @Transactional
    public void calculateAll(PayrollPeriodRequest request) {
        YearMonth period = YearMonth.of(request.year(), request.month());
        String key = period.format(PERIOD_FORMATTER);
        List<Employe> employees = employeRepository.findAllByStatutIgnoreCase("ACTIF");

        for (Employe employee : employees) {
            FichePaie fichePaie = fichePaieRepository.findByEmployeIdAndPeriode(employee.getId(), key)
                .orElseGet(FichePaie::new);
            if (fichePaie.isValidee()) {
                // Une fiche validée est verrouillée : aucun recalcul possible
                continue;
            }
            boolean nouvelle = fichePaie.getId() == null;

            // Moteur paramétrable : aucun taux codé en dur (voir PaieMoteurService).
            PaieMoteurService.Calcul calcul = paieMoteurService.calculer(employee, period);

            fichePaie.setEmploye(employee);
            fichePaie.setPeriode(key);
            fichePaie.setSalaireBrut(calcul.brut());
            fichePaie.setCotisations(calcul.cotisations());
            fichePaie.setImpots(calcul.impots());
            fichePaie.setIndemnites(calcul.indemnites());
            fichePaie.setAutresRetenues(calcul.autresRetenues());
            fichePaie.setSalaireNet(calcul.net());
            fichePaie.setConformeReglementation(calcul.conforme());
            fichePaie.setAvertissement(calcul.avertissement());
            fichePaie.setCalculee(true);

            fichePaieRepository.save(fichePaie);
            ligneBulletinRepository.deleteByFichePaieId(fichePaie.getId());
            for (PaieMoteurService.Ligne l : calcul.lignes()) {
                LigneBulletin ligne = new LigneBulletin();
                ligne.setFichePaie(fichePaie);
                ligne.setRubriqueCode(l.code());
                ligne.setLibelle(l.libelle());
                ligne.setType(l.type());
                ligne.setOrdre(l.ordre());
                ligne.setMontant(l.montant());
                ligne.setFormule(l.formule());
                ligne.setParametresUtilises(l.parametresUtilises());
                ligneBulletinRepository.save(ligne);
            }

            // Notifier l'employé lors de la première mise à disposition du bulletin
            if (nouvelle && employee.getUtilisateur() != null) {
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

    /** Bulletins de l'employé connecté. */
    @Transactional(readOnly = true)
    public Map<String, Object> listMine() {
        Employe employe = acl.currentEmploye()
            .orElseThrow(() -> new ResourceNotFoundException("Employé associé introuvable."));
        return Map.of("items", fichePaieRepository.findByEmployeIdOrderByPeriodeDesc(employe.getId())
            .stream().map(FichePaieResponse::fromEntity).toList());
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
            if (!fichePaie.isConformeReglementation()) {
                String warning = fichePaie.getAvertissement() != null ? fichePaie.getAvertissement()
                    : PaieMoteurService.AVERTISSEMENT_NON_VALIDE;
                document.add(new Paragraph(warning, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 11)));
            }
            document.add(new Paragraph(" "));
            for (LigneBulletin ligne : ligneBulletinRepository.findByFichePaieIdOrderByOrdreAsc(fichePaie.getId())) {
                document.add(new Paragraph(ligne.getLibelle() + " (" + ligne.getType() + "): " + ligne.getMontant()));
            }
            document.add(new Paragraph(" "));
            document.add(new Paragraph("Salaire brut: " + fichePaie.getSalaireBrut()));
            document.add(new Paragraph("Cotisations salariales: " + fichePaie.getCotisations()));
            document.add(new Paragraph("Impôts: " + fichePaie.getImpots()));
            document.add(new Paragraph("Autres retenues: " + fichePaie.getAutresRetenues()));
            document.add(new Paragraph("Salaire net: " + fichePaie.getSalaireNet(), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14)));
            document.close();
            return outputStream.toByteArray();
        } catch (Exception exception) {
            throw new IllegalStateException("La génération du PDF a échoué.", exception);
        }
    }

    @Auditable(action = "VALIDATE_PAYROLL", entite = "FichePaie")
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
