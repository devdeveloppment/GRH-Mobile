package com.grhmobile.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import com.grhmobile.audit.Auditable;
import com.grhmobile.dto.employee.EmployeeRequest;
import com.grhmobile.dto.employee.EmployeeResponse;
import com.grhmobile.exception.BusinessException;
import com.grhmobile.repository.ServiceRepository;
import com.grhmobile.repository.UtilisateurRepository;
import com.grhmobile.tenant.TenantContext;
import com.grhmobile.util.FileSignature;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

/**
 * Import Excel des employés, en deux temps : aperçu (aucune écriture) puis import confirmé.
 * <ul>
 *   <li>colonnes vérifiées, formats contrôlés, doublons détectés (dans le fichier et en base) ;</li>
 *   <li>aucune donnée existante n'est modifiée : un e-mail déjà connu est signalé et ignoré ;</li>
 *   <li>l'import est refusé tant qu'une ligne est en erreur (tout ou rien, en une transaction) ;</li>
 *   <li>les formules Excel ne sont jamais évaluées (valeurs lues comme texte).</li>
 * </ul>
 */
@Service
public class ImportEmployesService {

    public static final List<String> COLONNES = List.of(
        "nom", "prenom", "email", "telephone", "poste", "service", "typeContrat", "dateEmbauche", "dateFin", "salaire");
    private static final Set<String> OBLIGATOIRES = Set.of("nom", "prenom", "email", "poste", "service", "typeContrat", "salaire");
    private static final Set<String> CONTRATS = Set.of("CDI", "CDD", "STAGE");
    static final int MAX_LIGNES = 1000;
    private static final long MAX_OCTETS = 2L * 1024 * 1024;

    private final EmployeeService employeeService;
    private final UtilisateurRepository utilisateurRepository;
    private final ServiceRepository serviceRepository;

    public ImportEmployesService(EmployeeService employeeService, UtilisateurRepository utilisateurRepository,
                                 ServiceRepository serviceRepository) {
        this.employeeService = employeeService;
        this.utilisateurRepository = utilisateurRepository;
        this.serviceRepository = serviceRepository;
    }

    /** Modèle téléchargeable : en-têtes, une ligne d'exemple fictive et une feuille de consignes. */
    public byte[] modele() {
        try (XSSFWorkbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet s = wb.createSheet("Employes");
            Row h = s.createRow(0);
            for (int i = 0; i < COLONNES.size(); i++) {
                h.createCell(i).setCellValue(COLONNES.get(i));
            }
            String[] exemple = {"Exemple", "Fictif", "exemple.fictif@exemple.test", "+228 00 00 00 00", "Comptable",
                "Finance", "CDI", "2026-01-15", "", "250000"};
            Row r = s.createRow(1);
            for (int i = 0; i < exemple.length; i++) {
                r.createCell(i).setCellValue(exemple[i]);
            }
            Sheet c = wb.createSheet("Consignes");
            String[] lignes = {
                "Supprimez la ligne d'exemple avant l'import.",
                "Colonnes obligatoires : " + String.join(", ", OBLIGATOIRES.stream().sorted().toList()) + ".",
                "typeContrat : CDI, CDD ou STAGE. Dates au format AAAA-MM-JJ. dateFin obligatoire pour un CDD.",
                "salaire : nombre positif, sans séparateur de milliers.",
                "service : nom d'un service existant (un service inconnu sera créé, signalé dans l'aperçu).",
                "Un e-mail déjà utilisé est ignoré : aucun employé existant n'est modifié.",
                "Chaque employé importé reçoit un compte avec un mot de passe temporaire à changer.",
                "Maximum " + MAX_LIGNES + " lignes par fichier."};
            for (int i = 0; i < lignes.length; i++) {
                c.createRow(i).createCell(0).setCellValue(lignes[i]);
            }
            wb.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Génération du modèle impossible.", e);
        }
    }

    /** Analyse le fichier sans rien écrire. */
    @Transactional(readOnly = true)
    public Map<String, Object> apercu(MultipartFile file) {
        return analyser(file).resume();
    }

    /** Importe les lignes valides ; refusé si une ligne est en erreur. Les doublons sont ignorés. */
    @Auditable(action = "IMPORT_EMPLOYEES", entite = "Employe")
    @Transactional
    public Map<String, Object> importer(MultipartFile file) {
        Analyse a = analyser(file);
        if (a.erreurs > 0) {
            throw new BusinessException(a.erreurs + " ligne(s) en erreur : corrigez le fichier (voir l'aperçu) avant l'import.");
        }
        List<Map<String, Object>> crees = new ArrayList<>();
        for (Ligne l : a.lignes) {
            if (!"VALIDE".equals(l.statut)) {
                continue;
            }
            EmployeeResponse r = employeeService.create(l.requete);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("ligne", l.numero);
            m.put("matricule", r.matricule());
            m.put("email", l.requete.email());
            m.put("motDePasseTemporaire", r.motDePasseTemporaire());
            crees.add(m);
        }
        Map<String, Object> resume = a.resume();
        resume.put("importes", crees.size());
        resume.put("crees", crees);
        return resume;
    }

    // ── Analyse ─────────────────────────────────────────────────────────────

    private Analyse analyser(MultipartFile file) {
        FileSignature.verifier(file, Set.of(".xlsx"), MAX_OCTETS);
        Analyse a = new Analyse();
        try (InputStream in = file.getInputStream(); Workbook wb = new XSSFWorkbook(in)) {
            Sheet s = wb.getSheetAt(0);
            DataFormatter fmt = new DataFormatter(Locale.ROOT);
            Row entete = s.getRow(s.getFirstRowNum());
            if (entete == null) {
                throw new BusinessException("Le fichier est vide.");
            }
            Map<String, Integer> index = new LinkedHashMap<>();
            for (Cell c : entete) {
                index.put(fmt.formatCellValue(c).trim(), c.getColumnIndex());
            }
            List<String> manquantes = COLONNES.stream().filter(col -> OBLIGATOIRES.contains(col) && !index.containsKey(col)).toList();
            if (!manquantes.isEmpty()) {
                throw new BusinessException("Colonnes obligatoires manquantes : " + String.join(", ", manquantes)
                    + ". Utilisez le modèle téléchargeable.");
            }
            List<String> inconnues = index.keySet().stream().filter(k -> !k.isBlank() && !COLONNES.contains(k)).toList();
            a.colonnesIgnorees = inconnues;
            Set<String> emailsFichier = new HashSet<>();
            Set<String> servicesConnus = new HashSet<>();
            serviceRepository.findAll().forEach(sv -> servicesConnus.add(sv.getNom().toLowerCase(Locale.ROOT)));
            for (int i = s.getFirstRowNum() + 1; i <= s.getLastRowNum(); i++) {
                Row row = s.getRow(i);
                Map<String, String> v = new LinkedHashMap<>();
                for (String col : COLONNES) {
                    Integer idx = index.get(col);
                    v.put(col, idx == null || row == null ? "" : valeur(row.getCell(idx), fmt));
                }
                if (v.values().stream().allMatch(String::isBlank)) {
                    continue;
                }
                if (a.lignes.size() >= MAX_LIGNES) {
                    throw new BusinessException("Plus de " + MAX_LIGNES + " lignes : découpez le fichier.");
                }
                a.lignes.add(verifierLigne(i + 1, v, emailsFichier, servicesConnus));
            }
        } catch (BusinessException e) {
            throw e;
        } catch (IOException | RuntimeException e) {
            throw new BusinessException("Fichier Excel illisible.");
        }
        for (Ligne l : a.lignes) {
            switch (l.statut) {
                case "ERREUR" -> a.erreurs++;
                case "DOUBLON" -> a.doublons++;
                default -> a.valides++;
            }
        }
        return a;
    }

    /** Valeur de cellule en texte ; une formule est lue telle quelle (jamais évaluée). */
    private static String valeur(Cell c, DataFormatter fmt) {
        if (c == null) {
            return "";
        }
        if (c.getCellType() == org.apache.poi.ss.usermodel.CellType.NUMERIC && DateUtil.isCellDateFormatted(c)) {
            return c.getLocalDateTimeCellValue().toLocalDate().toString();
        }
        if (c.getCellType() == org.apache.poi.ss.usermodel.CellType.FORMULA) {
            return "=" + c.getCellFormula();
        }
        return fmt.formatCellValue(c).trim();
    }

    private Ligne verifierLigne(int numero, Map<String, String> v, Set<String> emailsFichier, Set<String> servicesConnus) {
        Ligne l = new Ligne();
        l.numero = numero;
        l.donnees = v;
        for (String col : COLONNES) {
            String x = v.get(col);
            if (x.startsWith("=")) {
                l.erreurs.add(col + " : formule refusée");
            }
            if (OBLIGATOIRES.contains(col) && x.isBlank()) {
                l.erreurs.add(col + " : obligatoire");
            }
            if (x.length() > 200) {
                l.erreurs.add(col + " : trop long (200 caractères max)");
            }
        }
        String email = v.get("email").toLowerCase(Locale.ROOT);
        if (!email.isBlank() && !email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            l.erreurs.add("email : format invalide");
        }
        String contrat = v.get("typeContrat").toUpperCase(Locale.ROOT);
        if (!contrat.isBlank() && !CONTRATS.contains(contrat)) {
            l.erreurs.add("typeContrat : attendu CDI, CDD ou STAGE");
        }
        LocalDate embauche = date(v.get("dateEmbauche"), "dateEmbauche", l);
        LocalDate fin = date(v.get("dateFin"), "dateFin", l);
        if ("CDD".equals(contrat) && fin == null && v.get("dateFin").isBlank()) {
            l.erreurs.add("dateFin : obligatoire pour un CDD");
        }
        if (embauche != null && fin != null && fin.isBefore(embauche)) {
            l.erreurs.add("dateFin : antérieure à la date d'embauche");
        }
        BigDecimal salaire = null;
        if (!v.get("salaire").isBlank()) {
            try {
                salaire = new BigDecimal(v.get("salaire").replace(" ", "").replace(',', '.'));
                if (salaire.signum() <= 0) {
                    l.erreurs.add("salaire : doit être positif");
                }
            } catch (NumberFormatException e) {
                l.erreurs.add("salaire : nombre attendu");
            }
        }
        if (!v.get("service").isBlank() && !servicesConnus.contains(v.get("service").toLowerCase(Locale.ROOT))) {
            l.avertissements.add("service « " + v.get("service") + " » inconnu : il sera créé");
        }
        if (!l.erreurs.isEmpty()) {
            l.statut = "ERREUR";
            return l;
        }
        if (!emailsFichier.add(email)) {
            l.statut = "DOUBLON";
            l.avertissements.add("e-mail présent plusieurs fois dans le fichier : seule la première ligne est importée");
            return l;
        }
        // L'e-mail est unique sur toute la plateforme (D2) : vérification hors filtre d'entreprise.
        if (TenantContext.systeme(() -> utilisateurRepository.findByEmailIgnoreCase(email).isPresent())) {
            l.statut = "DOUBLON";
            l.avertissements.add("e-mail déjà utilisé : ligne ignorée, aucune donnée existante n'est modifiée");
            return l;
        }
        l.statut = "VALIDE";
        l.requete = new EmployeeRequest(v.get("nom"), v.get("prenom"), null, null, null, email,
            v.get("telephone").isBlank() ? null : v.get("telephone"), "ACTIF", embauche != null ? embauche : LocalDate.now(),
            v.get("poste"), v.get("service"), contrat, null, fin, null, salaire, null, null, null);
        return l;
    }

    private static LocalDate date(String x, String col, Ligne l) {
        if (x == null || x.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(x);
        } catch (Exception e) {
            l.erreurs.add(col + " : date attendue au format AAAA-MM-JJ");
            return null;
        }
    }

    private static final class Ligne {
        int numero;
        Map<String, String> donnees;
        String statut;
        List<String> erreurs = new ArrayList<>();
        List<String> avertissements = new ArrayList<>();
        EmployeeRequest requete;
    }

    private static final class Analyse {
        List<Ligne> lignes = new ArrayList<>();
        List<String> colonnesIgnorees = List.of();
        int valides;
        int erreurs;
        int doublons;

        Map<String, Object> resume() {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("total", lignes.size());
            m.put("valides", valides);
            m.put("erreurs", erreurs);
            m.put("doublons", doublons);
            m.put("colonnesIgnorees", colonnesIgnorees);
            m.put("importable", erreurs == 0 && valides > 0);
            List<Map<String, Object>> detail = new ArrayList<>();
            for (Ligne l : lignes) {
                Map<String, Object> d = new LinkedHashMap<>();
                d.put("ligne", l.numero);
                d.put("statut", l.statut);
                d.put("nom", l.donnees.get("prenom") + " " + l.donnees.get("nom"));
                d.put("email", l.donnees.get("email"));
                d.put("erreurs", l.erreurs);
                d.put("avertissements", l.avertissements);
                detail.add(d);
            }
            m.put("lignes", detail);
            return m;
        }
    }
}
