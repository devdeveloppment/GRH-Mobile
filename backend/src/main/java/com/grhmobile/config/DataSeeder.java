package com.grhmobile.config;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.util.List;

import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Presence;
import com.grhmobile.entity.ServiceEntity;
import com.grhmobile.entity.Utilisateur;
import com.grhmobile.enums.Genre;
import com.grhmobile.enums.Role;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.enums.TypeConge;
import com.grhmobile.enums.TypeContrat;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PresenceRepository;
import com.grhmobile.repository.ServiceRepository;
import com.grhmobile.repository.UtilisateurRepository;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataSeeder {

    @Bean
    CommandLineRunner seedDemoData(
        UtilisateurRepository utilisateurRepository,
        ServiceRepository serviceRepository,
        EmployeRepository employeRepository,
        PresenceRepository presenceRepository,
        CongeRepository congeRepository,
        FichePaieRepository fichePaieRepository,
        PasswordEncoder passwordEncoder,
        AppProperties appProperties
    ) {
        return args -> {
            boolean databaseEmpty = utilisateurRepository.count() == 0;
            Utilisateur admin = ensureBootstrapAdmin(
                utilisateurRepository,
                passwordEncoder,
                appProperties.getBootstrapAdmin()
            );

            if (!databaseEmpty) {
                return;
            }

            ServiceEntity finance = saveService(serviceRepository, "Finance", "Gestion comptable et trésorerie", "Kokou Mensah");
            ServiceEntity rh = saveService(serviceRepository, "Ressources Humaines", "Administration du personnel", "Aminata Sanni");
            ServiceEntity commercial = saveService(serviceRepository, "Commercial", "Développement du portefeuille client", "Yaw Lawson");
            ServiceEntity operations = saveService(serviceRepository, "Opérations", "Pilotage des activités terrain", "Akouvi Edorh");

            Utilisateur hrManager = saveUser(utilisateurRepository, passwordEncoder, "Aminata", "Sanni", "rh@grh-mobile.com", Role.RH_MANAGER);
            Utilisateur employeeUser = saveUser(utilisateurRepository, passwordEncoder, "Ama", "Tossou", "employee@grh-mobile.com", Role.EMPLOYEE);
            Utilisateur direction = saveUser(utilisateurRepository, passwordEncoder, "Komi", "Tsevi", "direction@grh-mobile.com", Role.DIRECTION);

            Employe e1 = saveEmployee(employeRepository, employeeUser, "GRH-AT-240421-001", "Tossou", "Ama", employeeUser.getEmail(), "Développeuse Mobile", rh, BigDecimal.valueOf(450000), Genre.FEMME);
            Employe e2 = saveEmployee(employeRepository, null, "GRH-KM-240421-002", "Mensah", "Kokou", "kokou.mensah@grh-mobile.com", "Comptable Senior", finance, BigDecimal.valueOf(520000), Genre.HOMME);
            Employe e3 = saveEmployee(employeRepository, null, "GRH-YL-240421-003", "Lawson", "Yaw", "yaw.lawson@grh-mobile.com", "Business Developer", commercial, BigDecimal.valueOf(390000), Genre.HOMME);
            Employe e4 = saveEmployee(employeRepository, null, "GRH-AE-240421-004", "Edorh", "Akouvi", "akouvi.edorh@grh-mobile.com", "Responsable Opérations", operations, BigDecimal.valueOf(610000), Genre.FEMME);
            Employe e5 = saveEmployee(employeRepository, null, "GRH-AS-240421-005", "Sanni", "Aminata", hrManager.getEmail(), "RH Manager", rh, BigDecimal.valueOf(700000), Genre.FEMME);
            Employe e6 = saveEmployee(employeRepository, null, "GRH-KT-240421-006", "Tsevi", "Komi", direction.getEmail(), "Directeur Général", operations, BigDecimal.valueOf(950000), Genre.HOMME);

            List<Employe> employees = List.of(e1, e2, e3, e4, e5, e6);

            seedPresences(presenceRepository, employees);
            seedConges(congeRepository, e1, e3, e5);
            seedPaie(fichePaieRepository, employees);

            admin.setDateCreation(OffsetDateTime.now().minusMonths(8));
            utilisateurRepository.save(admin);
        };
    }

    private Utilisateur ensureBootstrapAdmin(
        UtilisateurRepository repository,
        PasswordEncoder encoder,
        AppProperties.BootstrapAdmin config
    ) {
        if (!config.isEnabled()) {
            return null;
        }

        Utilisateur admin = repository.findByEmailIgnoreCase(config.getEmail())
            .orElseGet(Utilisateur::new);

        boolean isNewUser = admin.getId() == null;
        admin.setNom(config.getNom());
        admin.setPrenom(config.getPrenom());
        admin.setEmail(config.getEmail());
        admin.setRole(Role.ADMIN);
        admin.setActif(true);

        if (isNewUser) {
            admin.setDateCreation(OffsetDateTime.now().minusMonths(8));
        }

        if (isNewUser || config.isResetPasswordOnStartup()) {
            admin.setMotDePasse(encoder.encode(config.getPassword()));
        }

        return repository.save(admin);
    }

    private ServiceEntity saveService(
        ServiceRepository repository,
        String nom,
        String description,
        String responsable
    ) {
        ServiceEntity service = new ServiceEntity();
        service.setNom(nom);
        service.setDescription(description);
        service.setResponsable(responsable);
        return repository.save(service);
    }

    private Utilisateur saveUser(
        UtilisateurRepository repository,
        PasswordEncoder encoder,
        String nom,
        String prenom,
        String email,
        Role role
    ) {
        Utilisateur user = new Utilisateur();
        user.setNom(nom);
        user.setPrenom(prenom);
        user.setEmail(email);
        user.setRole(role);
        user.setMotDePasse(encoder.encode("ChangeMe@123"));
        user.setDateCreation(OffsetDateTime.now().minusMonths(4));
        return repository.save(user);
    }

    private Employe saveEmployee(
        EmployeRepository repository,
        Utilisateur utilisateur,
        String matricule,
        String nom,
        String prenom,
        String email,
        String poste,
        ServiceEntity service,
        BigDecimal salaire,
        Genre genre
    ) {
        Employe employe = new Employe();
        employe.setMatricule(matricule);
        employe.setNom(nom);
        employe.setPrenom(prenom);
        employe.setEmail(email);
        employe.setTelephone("+228 90 00 00 00");
        employe.setStatut("ACTIF");
        employe.setDateEmbauche(LocalDate.now().minusMonths(18));
        employe.setDateNaissance(LocalDate.now().minusYears(29));
        employe.setGenre(genre);
        employe.setNationalite("Togolaise");
        employe.setPoste(poste);
        employe.setService(service);
        employe.setTypeContrat(TypeContrat.CDI);
        employe.setAdresse("Lomé, Togo");
        employe.setSalaireBrutBase(salaire);
        employe.setUtilisateur(utilisateur);
        return repository.save(employe);
    }

    private void seedPresences(PresenceRepository repository, List<Employe> employees) {
        for (Employe employe : employees) {
            for (int daysBack = 0; daysBack < 7; daysBack++) {
                LocalDate date = LocalDate.now().minusDays(daysBack);
                Presence presence = new Presence();
                presence.setEmploye(employe);
                presence.setDate(date);
                if (daysBack == 2 && employe.getPrenom().equals("Yaw")) {
                    presence.setStatut(StatutPresence.ABSENT);
                } else if (daysBack == 1 && employe.getPrenom().equals("Ama")) {
                    presence.setStatut(StatutPresence.RETARD);
                    presence.setHeureArrivee(LocalDateTime.of(date, java.time.LocalTime.of(9, 5)));
                    presence.setHeureDepart(LocalDateTime.of(date, java.time.LocalTime.of(17, 20)));
                } else {
                    presence.setStatut(StatutPresence.PRESENT);
                    presence.setHeureArrivee(LocalDateTime.of(date, java.time.LocalTime.of(8, 2)));
                    presence.setHeureDepart(LocalDateTime.of(date, java.time.LocalTime.of(17, 5)));
                }
                repository.save(presence);
            }
        }
    }

    private void seedConges(CongeRepository repository, Employe e1, Employe e3, Employe e5) {
        Conge pending = new Conge();
        pending.setEmploye(e1);
        pending.setTypeConge(TypeConge.ANNUEL);
        pending.setDateDebut(LocalDate.now().plusDays(5));
        pending.setDateFin(LocalDate.now().plusDays(8));
        pending.setNombreJours(4);
        pending.setStatut(StatutConge.EN_ATTENTE);
        pending.setMotif("Repos annuel");
        repository.save(pending);

        Conge approved = new Conge();
        approved.setEmploye(e3);
        approved.setTypeConge(TypeConge.MALADIE);
        approved.setDateDebut(LocalDate.now().minusDays(10));
        approved.setDateFin(LocalDate.now().minusDays(8));
        approved.setNombreJours(3);
        approved.setStatut(StatutConge.APPROUVE);
        approved.setMotif("Arrêt médical");
        repository.save(approved);

        Conge rejected = new Conge();
        rejected.setEmploye(e5);
        rejected.setTypeConge(TypeConge.SANS_SOLDE);
        rejected.setDateDebut(LocalDate.now().plusDays(12));
        rejected.setDateFin(LocalDate.now().plusDays(14));
        rejected.setNombreJours(3);
        rejected.setStatut(StatutConge.REFUSE);
        rejected.setCommentaire("Période sensible pour la clôture RH.");
        repository.save(rejected);
    }

    private void seedPaie(FichePaieRepository repository, List<Employe> employees) {
        String currentPeriod = FichePaie.formatPeriode(YearMonth.now());
        for (Employe employe : employees) {
            FichePaie payslip = new FichePaie();
            payslip.setEmploye(employe);
            payslip.setPeriode(currentPeriod);
            payslip.setSalaireBrut(employe.getSalaireBrutBase());
            payslip.setCotisations(employe.getSalaireBrutBase().multiply(BigDecimal.valueOf(0.04)));
            payslip.setImpots(employe.getSalaireBrutBase().multiply(BigDecimal.valueOf(0.08)));
            payslip.setIndemnites(employe.getSalaireBrutBase().multiply(BigDecimal.valueOf(0.05)));
            payslip.setSalaireNet(
                payslip.getSalaireBrut()
                    .subtract(payslip.getCotisations())
                    .subtract(payslip.getImpots())
                    .add(payslip.getIndemnites())
            );
            payslip.setCalculee(true);
            repository.save(payslip);
        }
    }
}
