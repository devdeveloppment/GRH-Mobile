package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockMultipartFile;

/**
 * Sécurité de la phase de finalisation :
 * révocation des jetons, contrôle réel des fichiers déposés, cloisonnement des exports de rapports.
 */
class SecuriteCompletionIT extends AbstractIntegrationTest {

    private static final String MDP = "Jeton-Test-2026!";

    private int code(String url, String token) throws Exception {
        return mvc.perform(get(url).header("Authorization", token)).andReturn().getResponse().getStatus();
    }

    /** Crée un utilisateur jetable dans l'entreprise de l'administrateur A ; renvoie son id. */
    private long creerUtilisateur(String email, String role) throws Exception {
        String r = mvc.perform(post("/api/admin/users").header("Authorization", bearer(ADMIN))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("email", email, "fullName", "Test Jeton",
                    "role", role, "password", MDP))))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return json(r).get("id").asLong();
    }

    private String connecter(String email, String mdp) throws Exception {
        String r = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("email", email, "password", mdp))))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return "Bearer " + json(r).get("token").asText();
    }

    private static String email() {
        return "jeton-" + UUID.randomUUID().toString().substring(0, 8) + "@grh-mobile.com";
    }

    // ── Révocation des jetons ───────────────────────────────────────────────

    @Test
    void deconnexionRevoqueLeJetonPresente() throws Exception {
        String e = email();
        creerUtilisateur(e, "EMPLOYEE");
        String t1 = connecter(e, MDP);
        String t2 = connecter(e, MDP);
        assertThat(code("/api/auth/me", t1)).isEqualTo(200);
        mvc.perform(post("/api/auth/logout").header("Authorization", t1));
        assertThat(code("/api/auth/me", t1)).as("jeton déconnecté").isEqualTo(401);
        assertThat(code("/api/auth/me", t2)).as("autre session intacte").isEqualTo(200);
        mvc.perform(post("/api/auth/logout-all").header("Authorization", t2));
        assertThat(code("/api/auth/me", t2)).as("toutes sessions").isEqualTo(401);
        assertThat(code("/api/auth/me", connecter(e, MDP))).as("nouvelle connexion").isEqualTo(200);
    }

    @Test
    void changementDeMotDePasseRevoqueLesAnciensJetons() throws Exception {
        String e = email();
        creerUtilisateur(e, "EMPLOYEE");
        String ancien = connecter(e, MDP);
        String courant = connecter(e, MDP);
        mvc.perform(put("/api/profile/password").header("Authorization", courant)
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(Map.of("currentPassword", MDP, "newPassword", "Nouveau-Mdp-2026!"))));
        assertThat(code("/api/auth/me", ancien)).isEqualTo(401);
        assertThat(code("/api/auth/me", courant)).isEqualTo(401);
        assertThat(code("/api/auth/me", connecter(e, "Nouveau-Mdp-2026!"))).isEqualTo(200);
    }

    @Test
    void desactivationChangementDeRoleEtRevocationAdministrative() throws Exception {
        String admin = bearer(ADMIN);
        String e = email();
        long id = creerUtilisateur(e, "EMPLOYEE");

        String t = connecter(e, MDP);
        mvc.perform(put("/api/admin/users/" + id + "/role").header("Authorization", admin)
            .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"MANAGER\"}"));
        assertThat(code("/api/auth/me", t)).as("après changement de rôle").isEqualTo(401);

        t = connecter(e, MDP);
        mvc.perform(post("/api/admin/users/" + id + "/revoquer-sessions").header("Authorization", admin));
        assertThat(code("/api/auth/me", t)).as("révocation administrative").isEqualTo(401);

        t = connecter(e, MDP);
        mvc.perform(delete("/api/admin/users/" + id).header("Authorization", admin));
        assertThat(code("/api/auth/me", t)).as("compte désactivé").isEqualTo(401);
        // Réactivation : l'ancien jeton reste invalide.
        mvc.perform(put("/api/admin/users/" + id + "/toggle").header("Authorization", admin));
        assertThat(code("/api/auth/me", t)).as("ancien jeton après réactivation").isEqualTo(401);
    }

    @Test
    void revocationAdministrativeEntreEntreprisesRefusee() throws Exception {
        long id = creerUtilisateur(email(), "EMPLOYEE");
        int s = mvc.perform(post("/api/admin/users/" + id + "/revoquer-sessions").header("Authorization", bearer(ADMIN_B)))
            .andReturn().getResponse().getStatus();
        assertThat(s).isIn(403, 404);
    }

    @Test
    void jetonFalsifieOuSansVersionRefuse() throws Exception {
        String t = bearer(EMPLOYEE);
        String[] parts = t.substring(7).split("\\.");
        String falsifie = "Bearer " + parts[0] + "." + parts[1] + "." + "AAAA" + parts[2].substring(4);
        assertThat(code("/api/auth/me", falsifie)).isEqualTo(401);
    }

    // ── Fichiers déposés ────────────────────────────────────────────────────

    private static final byte[] PDF = "%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF".getBytes(StandardCharsets.US_ASCII);
    private static final byte[] EXE = new byte[]{'M', 'Z', (byte) 0x90, 0, 3, 0, 0, 0, 4, 0};

    private int candidature(String nomFichier, byte[] contenu) throws Exception {
        Long offre = longEntreprise(1, "SELECT id FROM offres_emploi WHERE statut = 'PUBLIEE' ORDER BY id LIMIT 1");
        return mvc.perform(multipart("/api/offres/" + offre + "/candidatures/upload").file(
                    new MockMultipartFile("cv", nomFichier, "application/pdf", contenu))
                .param("entreprise", "defaut").param("nom", "Fictif").param("prenom", "Candidat")
                .param("email", "candidat@exemple.test"))
            .andReturn().getResponse().getStatus();
    }

    @Test
    void cvPublicVerifieParContenuReel() throws Exception {
        assertThat(candidature("cv.pdf", EXE)).as("exécutable renommé en .pdf").isEqualTo(400);
        assertThat(candidature("cv.pdf.exe", PDF)).as("double extension").isEqualTo(400);
        assertThat(candidature("cv.docx", PDF)).as("PDF déguisé en .docx").isEqualTo(400);
        assertThat(candidature("../../cv.pdf", PDF)).as("chemin dans le nom").isEqualTo(400);
        assertThat(candidature("cv.html", "<script>alert(1)</script>".getBytes())).isEqualTo(400);
        assertThat(candidature("cv.pdf", PDF)).as("vrai PDF").isEqualTo(201);
        assertThat(candidature("cv.docx", docx())).as("vrai DOCX").isEqualTo(201);
    }

    @Test
    void documentRhVerifieParContenuReel() throws Exception {
        String rh = bearer(ADMIN);
        String matricule = jdbcMatricule();
        int faux = mvc.perform(multipart("/api/employees/" + matricule + "/documents")
                .file(new MockMultipartFile("file", "contrat.xlsx", "application/octet-stream", EXE))
                .header("Authorization", rh)).andReturn().getResponse().getStatus();
        assertThat(faux).isEqualTo(400);
        int vrai = mvc.perform(multipart("/api/employees/" + matricule + "/documents")
                .file(new MockMultipartFile("file", "contrat.pdf", "application/pdf", PDF))
                .header("Authorization", rh)).andReturn().getResponse().getStatus();
        assertThat(vrai).isEqualTo(201);
    }

    private String jdbcMatricule() {
        return sqlEntreprise(1, con -> {
            try (var rs = con.createStatement().executeQuery("SELECT matricule FROM employes ORDER BY id LIMIT 1")) {
                rs.next();
                return rs.getString(1);
            }
        });
    }

    private static byte[] docx() throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (ZipOutputStream z = new ZipOutputStream(out)) {
            z.putNextEntry(new ZipEntry("[Content_Types].xml"));
            z.write("<Types/>".getBytes());
            z.putNextEntry(new ZipEntry("word/document.xml"));
            z.write("<w:document/>".getBytes());
        }
        return out.toByteArray();
    }

    // ── Exports de rapports entre entreprises ───────────────────────────────

    private static final List<String> MARQUEURS_A = List.of("GRH-AT-240421", "GRH-KM-240421", "Tossou", "Mensah");
    private static final List<String> MARQUEURS_B = List.of("DEMOB-");

    /** Texte lisible de l'export, selon son format réel (PDF, XLSX, CSV). */
    private String texte(MockHttpServletResponse r) throws Exception {
        byte[] b = r.getContentAsByteArray();
        String type = String.valueOf(r.getContentType());
        if (type.contains("pdf")) {
            PdfReader reader = new PdfReader(b);
            StringBuilder sb = new StringBuilder();
            PdfTextExtractor ex = new PdfTextExtractor(reader);
            for (int p = 1; p <= reader.getNumberOfPages(); p++) {
                sb.append(ex.getTextFromPage(p)).append('\n');
            }
            return sb.toString();
        }
        if (type.contains("spreadsheet")) {
            StringBuilder sb = new StringBuilder();
            try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(b))) {
                for (Sheet s : wb) {
                    for (Row row : s) {
                        for (Cell c : row) {
                            sb.append(c.toString()).append(';');
                        }
                        sb.append('\n');
                    }
                }
            }
            return sb.toString();
        }
        return new String(b, StandardCharsets.UTF_8);
    }

    @Test
    void exportsDeRapportsCloisonnesParEntreprise() throws Exception {
        String a = bearer(ADMIN);
        String b = bearer(ADMIN_B);
        int controles = 0;
        for (String format : List.of("pdf", "xlsx")) {
            MockHttpServletResponse ra = mvc.perform(get("/api/reports/export").param("format", format)
                .header("Authorization", a)).andReturn().getResponse();
            MockHttpServletResponse rb = mvc.perform(get("/api/reports/export").param("format", format)
                .header("Authorization", b)).andReturn().getResponse();
            assertThat(ra.getStatus()).isEqualTo(200);
            assertThat(rb.getStatus()).isEqualTo(200);
            assertThat(texte(rb)).as("export %s de B", format).doesNotContain(MARQUEURS_A);
            assertThat(texte(ra)).as("export %s de A", format).doesNotContain(MARQUEURS_B);
            controles++;
        }
        boolean aVuSesDonnees = false;
        for (String type : List.of("PRESENCES", "CONGES", "PAIE", "EFFECTIFS")) {
            for (String format : List.of("PDF", "CSV")) {
                String req = objectMapper.writeValueAsString(Map.of("type", type, "format", format,
                    "debut", "2020-01-01", "fin", "2030-12-31"));
                MockHttpServletResponse ra = mvc.perform(post("/api/reports/generate").header("Authorization", a)
                    .contentType(MediaType.APPLICATION_JSON).content(req)).andReturn().getResponse();
                MockHttpServletResponse rb = mvc.perform(post("/api/reports/generate").header("Authorization", b)
                    .contentType(MediaType.APPLICATION_JSON).content(req)).andReturn().getResponse();
                assertThat(ra.getStatus()).as("%s %s", type, format).isEqualTo(200);
                assertThat(rb.getStatus()).as("%s %s", type, format).isEqualTo(200);
                String ta = texte(ra);
                String tb = texte(rb);
                assertThat(tb).as("rapport %s %s de B", type, format).doesNotContain(MARQUEURS_A);
                assertThat(ta).as("rapport %s %s de A", type, format).doesNotContain(MARQUEURS_B);
                if ("EFFECTIFS".equals(type)) {
                    // Témoin positif : chaque entreprise voit bien ses propres effectifs.
                    assertThat(tb).contains("DEMOB-");
                    aVuSesDonnees = ta.contains("GRH-");
                }
                controles++;
            }
        }
        assertThat(aVuSesDonnees).isTrue();
        assertThat(controles).isEqualTo(10);
        // Un employé n'a pas le droit d'exporter.
        assertThat(code("/api/reports/export?format=pdf", bearer(EMPLOYEE))).isEqualTo(403);
    }
}
