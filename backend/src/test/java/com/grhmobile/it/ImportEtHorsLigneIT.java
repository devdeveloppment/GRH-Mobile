package com.grhmobile.it;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.databind.JsonNode;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockMultipartFile;

/** Import Excel des employés et rejeu sans doublon des opérations hors ligne. */
class ImportEtHorsLigneIT extends AbstractIntegrationTest {

    private static byte[] classeur(String[][] lignes) throws Exception {
        try (XSSFWorkbook wb = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet s = wb.createSheet("Employes");
            for (int i = 0; i < lignes.length; i++) {
                Row r = s.createRow(i);
                for (int j = 0; j < lignes[i].length; j++) {
                    if (lignes[i][j].startsWith("=")) {
                        r.createCell(j).setCellFormula(lignes[i][j].substring(1));
                    } else {
                        r.createCell(j).setCellValue(lignes[i][j]);
                    }
                }
            }
            wb.write(out);
            return out.toByteArray();
        }
    }

    private MockHttpServletResponse envoyer(String url, byte[] contenu, String token) throws Exception {
        return mvc.perform(multipart(url).file(new MockMultipartFile("file", "import.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", contenu))
            .header("Authorization", token)).andReturn().getResponse();
    }

    private static final String[] ENTETE = {"nom", "prenom", "email", "telephone", "poste", "service",
        "typeContrat", "dateEmbauche", "dateFin", "salaire"};

    @Test
    void importExcelAvecApercuDoublonsEtErreurs() throws Exception {
        String rh = bearer(RH);
        String s = UUID.randomUUID().toString().substring(0, 6);

        // Modèle téléchargeable et lisible.
        MockHttpServletResponse modele = mvc.perform(get("/api/import/employes/modele").header("Authorization", rh))
            .andReturn().getResponse();
        assertThat(modele.getStatus()).isEqualTo(200);
        try (XSSFWorkbook wb = new XSSFWorkbook(new ByteArrayInputStream(modele.getContentAsByteArray()))) {
            assertThat(wb.getSheetAt(0).getRow(0).getCell(2).getStringCellValue()).isEqualTo("email");
        }

        byte[] avecErreurs = classeur(new String[][]{ENTETE,
            {"Import", "Un", "import1." + s + "@exemple.test", "", "Comptable", "Finance", "CDI", "2026-01-15", "", "200000"},
            {"Import", "Deux", "pas-un-email", "", "Comptable", "Finance", "CDD", "2026-01-15", "", "abc"},
            {"Import", "Trois", "import3." + s + "@exemple.test", "", "Comptable", "Finance", "CDI", "2026-01-15", "", "=1+1"},
            {"Existant", "Admin", ADMIN, "", "Directeur", "Finance", "CDI", "2026-01-15", "", "100"},
            {"Import", "Un bis", "import1." + s + "@exemple.test", "", "Comptable", "Finance", "CDI", "2026-01-15", "", "200000"}});
        JsonNode apercu = json(envoyer("/api/import/employes/apercu", avecErreurs, rh).getContentAsString(StandardCharsets.UTF_8));
        assertThat(apercu.get("total").asInt()).isEqualTo(5);
        assertThat(apercu.get("valides").asInt()).isEqualTo(1);
        assertThat(apercu.get("erreurs").asInt()).isEqualTo(2);   // e-mail/salaire/CDD sans fin ; formule
        assertThat(apercu.get("doublons").asInt()).isEqualTo(2);  // e-mail existant ; doublon dans le fichier
        assertThat(apercu.get("importable").asBoolean()).isFalse();
        assertThat(apercu.toString()).contains("formule refusée", "obligatoire pour un CDD", "déjà utilisé");
        // L'aperçu n'écrit rien ; l'import est refusé tant qu'il reste des erreurs.
        assertThat(longEntreprise(1, "SELECT count(*) FROM utilisateurs WHERE email LIKE ?", "import%." + s + "@exemple.test")).isZero();
        assertThat(envoyer("/api/import/employes", avecErreurs, rh).getStatus()).isEqualTo(400);

        String mdpAdminAvant = sqlEntreprise(1, con -> {
            try (var ps = con.prepareStatement("SELECT mot_de_passe FROM utilisateurs WHERE email = ?")) {
                ps.setString(1, ADMIN);
                try (var rs = ps.executeQuery()) { rs.next(); return rs.getString(1); }
            }
        });
        byte[] corrige = classeur(new String[][]{ENTETE,
            {"Import", "Un", "import1." + s + "@exemple.test", "", "Comptable", "Finance", "CDI", "2026-01-15", "", "200000"},
            {"Import", "Deux", "import2." + s + "@exemple.test", "", "Assistant", "Finance", "CDD", "2026-01-15", "2026-12-31", "150000"},
            {"Existant", "Admin", ADMIN, "", "Directeur", "Finance", "CDI", "2026-01-15", "", "100"}});
        JsonNode resultat = json(envoyer("/api/import/employes", corrige, rh).getContentAsString(StandardCharsets.UTF_8));
        assertThat(resultat.get("importes").asInt()).isEqualTo(2);
        assertThat(resultat.get("doublons").asInt()).isEqualTo(1);
        assertThat(resultat.get("crees").get(0).get("motDePasseTemporaire").asText()).isNotBlank();
        // Aucune donnée existante modifiée.
        String mdpAdminApres = sqlEntreprise(1, con -> {
            try (var ps = con.prepareStatement("SELECT mot_de_passe FROM utilisateurs WHERE email = ?")) {
                ps.setString(1, ADMIN);
                try (var rs = ps.executeQuery()) { rs.next(); return rs.getString(1); }
            }
        });
        assertThat(mdpAdminApres).isEqualTo(mdpAdminAvant);
        // Cloisonnement : importés dans l'entreprise de l'utilisateur uniquement.
        long b = jdbc.queryForObject("SELECT id FROM entreprises WHERE slug = 'demo-b'", Long.class);
        assertThat(longEntreprise(b, "SELECT count(*) FROM employes WHERE email LIKE ?", "import%." + s + "@exemple.test")).isZero();
        assertThat(longEntreprise(1, "SELECT count(*) FROM employes WHERE email LIKE ?", "import%." + s + "@exemple.test")).isEqualTo(2L);
        // Journalisé.
        assertThat(longEntreprise(1, "SELECT count(*) FROM audit_logs WHERE action = 'IMPORT_EMPLOYEES'")).isGreaterThan(0);

        // Faux fichier Excel et accès refusé à l'employé.
        assertThat(envoyer("/api/import/employes/apercu", "pas un classeur".getBytes(), rh).getStatus()).isEqualTo(400);
        assertThat(envoyer("/api/import/employes/apercu", corrige, bearer(EMPLOYEE)).getStatus()).isEqualTo(403);
    }

    @Test
    void colonnesObligatoiresVerifiees() throws Exception {
        byte[] incomplet = classeur(new String[][]{{"nom", "prenom"}, {"A", "B"}});
        MockHttpServletResponse r = envoyer("/api/import/employes/apercu", incomplet, bearer(RH));
        assertThat(r.getStatus()).isEqualTo(400);
        assertThat(r.getContentAsString(StandardCharsets.UTF_8)).contains("Colonnes obligatoires manquantes");
    }

    @Test
    void rejeuHorsLigneSansDoublon() throws Exception {
        String employe = bearer(EMPLOYEE);
        String cle = UUID.randomUUID().toString();
        LocalDate d = LocalDate.now().plusYears(3).plusDays((long) (Math.random() * 300));
        String corps = objectMapper.writeValueAsString(Map.of("typeConge", "SANS_SOLDE", "dateDebut", d.toString(),
            "dateFin", d.plusDays(1).toString(), "motif", "Saisi hors ligne"));
        MockHttpServletResponse r1 = mvc.perform(post("/api/conges").header("Authorization", employe)
            .header("Idempotency-Key", cle).contentType(MediaType.APPLICATION_JSON).content(corps)).andReturn().getResponse();
        MockHttpServletResponse r2 = mvc.perform(post("/api/conges").header("Authorization", employe)
            .header("Idempotency-Key", cle).contentType(MediaType.APPLICATION_JSON).content(corps)).andReturn().getResponse();
        assertThat(r1.getStatus()).isEqualTo(201);
        assertThat(r2.getStatus()).isEqualTo(201);
        assertThat(r2.getHeader("Idempotent-Replay")).isEqualTo("true");
        assertThat(json(r2.getContentAsString(StandardCharsets.UTF_8)).get("id").asLong())
            .isEqualTo(json(r1.getContentAsString(StandardCharsets.UTF_8)).get("id").asLong());
        assertThat(longEntreprise(1, "SELECT count(*) FROM conges WHERE date_debut = ? AND motif = 'Saisi hors ligne'",
            java.sql.Date.valueOf(d))).isEqualTo(1L);
        // La même clé ne peut pas servir à une autre opération.
        int autre = mvc.perform(multipart("/api/notes-frais").param("dateDepense", LocalDate.now().toString())
                .param("categorie", "REPAS").param("montant", "1000").param("description", "x")
                .header("Authorization", employe).header("Idempotency-Key", cle)).andReturn().getResponse().getStatus();
        assertThat(autre).isEqualTo(422);
        // Conflit métier rejoué avec une nouvelle clé : refusé (chevauchement), pas dupliqué.
        int conflit = mvc.perform(post("/api/conges").header("Authorization", employe)
            .header("Idempotency-Key", UUID.randomUUID().toString()).contentType(MediaType.APPLICATION_JSON).content(corps))
            .andReturn().getResponse().getStatus();
        assertThat(conflit).isEqualTo(400);
        // La clé d'un utilisateur ne donne pas accès à la réponse d'un autre.
        MockHttpServletResponse autreUtilisateur = mvc.perform(post("/api/conges").header("Authorization", bearer(RH))
            .header("Idempotency-Key", cle).contentType(MediaType.APPLICATION_JSON).content(corps)).andReturn().getResponse();
        assertThat(autreUtilisateur.getHeader("Idempotent-Replay")).isNull();
    }
}
