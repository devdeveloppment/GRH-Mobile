package com.grhmobile.service;

import com.grhmobile.repository.FormationRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import com.grhmobile.dto.dashboard.DashboardPointDto;
import com.grhmobile.dto.dashboard.DashboardSummaryResponse;
import com.grhmobile.dto.dashboard.RecentActivityDto;
import com.grhmobile.dto.dashboard.EnhancedDashboardResponse;
import com.grhmobile.dto.dashboard.LeaveRequestDto;
import com.grhmobile.dto.dashboard.BirthdayDto;
import com.grhmobile.dto.dashboard.QuickStatsDto;
import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Presence;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.StatutPresence;
import com.grhmobile.enums.TypeContrat;
import com.grhmobile.repository.CongeRepository;
import com.grhmobile.repository.EmployeRepository;
import com.grhmobile.repository.FichePaieRepository;
import com.grhmobile.repository.PresenceRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DashboardService {

    private static final Locale FRENCH = Locale.FRANCE;

    private final EmployeRepository employeRepository;
    private final PresenceRepository presenceRepository;
    private final CongeRepository congeRepository;
    private final FichePaieRepository fichePaieRepository;
    private final FormationRepository formationRepository;

    public DashboardService(
        EmployeRepository employeRepository,
        PresenceRepository presenceRepository,
        CongeRepository congeRepository,
        FichePaieRepository fichePaieRepository,
        FormationRepository formationRepository
    ) {
        this.formationRepository = formationRepository;
        this.employeRepository = employeRepository;
        this.presenceRepository = presenceRepository;
        this.congeRepository = congeRepository;
        this.fichePaieRepository = fichePaieRepository;
    }

    @Transactional(readOnly = true)
    public DashboardSummaryResponse getSummary() {
        LocalDate today = LocalDate.now();
        YearMonth currentMonth = YearMonth.now();
        List<Employe> employees = employeRepository.findAll();
        List<Conge> leaves = congeRepository.findAll();
        List<Presence> weeklyPresences = presenceRepository.findByDateBetweenOrderByDateAsc(today.minusDays(6), today);

        long totalEmployees = employees.stream().filter(employee -> "ACTIF".equalsIgnoreCase(employee.getStatut())).count();
        long presentToday = presenceRepository.countByDateAndStatut(today, StatutPresence.PRESENT);
        long pendingLeaves = congeRepository.countByStatut(StatutConge.EN_ATTENTE);
        long payslipsThisMonth = fichePaieRepository.countByPeriode(FichePaie.formatPeriode(currentMonth));

        // Masse salariale mensuelle des seuls employés actifs
        BigDecimal payrollMass = employees.stream()
            .filter(employee -> "ACTIF".equalsIgnoreCase(employee.getStatut()))
            .map(Employe::getSalaireBrutBase)
            .filter(java.util.Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        long totalCheckinsToday = presenceRepository.countByDate(today);
        double attendanceRate = totalEmployees == 0 ? 0
            : BigDecimal.valueOf(presentToday * 100d / totalEmployees).setScale(1, RoundingMode.HALF_UP).doubleValue();

        long approvedLeaves = leaves.stream().filter(leave -> leave.getStatut() == StatutConge.APPROUVE).count();
        long archivedEmployees = employees.stream().filter(employee -> "ARCHIVE".equalsIgnoreCase(employee.getStatut())).count();
        double turnoverRate = totalEmployees == 0 ? 0
            : BigDecimal.valueOf(archivedEmployees * 100d / Math.max(employees.size(), 1)).setScale(1, RoundingMode.HALF_UP).doubleValue();

        return new DashboardSummaryResponse(
            totalEmployees,
            presentToday,
            pendingLeaves,
            payslipsThisMonth,
            payrollMass.doubleValue(),
            totalCheckinsToday == 0 ? attendanceRate : attendanceRate,
            approvedLeaves,
            turnoverRate,
            buildWeeklyAttendance(weeklyPresences),
            buildPayrollEvolution(),
            buildDepartmentBreakdown(employees),
            buildRecentActivities(leaves, weeklyPresences)
        );
    }

    private List<DashboardPointDto> buildWeeklyAttendance(List<Presence> presences) {
        Map<LocalDate, Long> grouped = new LinkedHashMap<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            grouped.put(date, 0L);
        }
        for (Presence presence : presences) {
            if (presence.getStatut() == StatutPresence.PRESENT) {
                grouped.computeIfPresent(presence.getDate(), (date, count) -> count + 1);
            }
        }
        return grouped.entrySet()
            .stream()
            .map(entry -> new DashboardPointDto(
                entry.getKey().getDayOfWeek().getDisplayName(TextStyle.SHORT, FRENCH),
                entry.getValue()
            ))
            .toList();
    }

    /** Masse salariale brute réellement calculée (fiches de paie) sur les 6 derniers mois. */
    private List<DashboardPointDto> buildPayrollEvolution() {
        YearMonth end = YearMonth.now();
        YearMonth start = end.minusMonths(5);
        Map<String, BigDecimal> totals = new LinkedHashMap<>();
        for (int i = 0; i < 6; i++) {
            totals.put(FichePaie.formatPeriode(start.plusMonths(i)), BigDecimal.ZERO);
        }
        fichePaieRepository.findByPeriodeBetweenOrderByPeriodeAscEmployeNomAsc(
                FichePaie.formatPeriode(start), FichePaie.formatPeriode(end))
            .forEach(fiche -> totals.computeIfPresent(fiche.getPeriode(),
                (key, sum) -> sum.add(fiche.getSalaireBrut() != null ? fiche.getSalaireBrut() : BigDecimal.ZERO)));
        List<DashboardPointDto> points = new ArrayList<>();
        int index = 0;
        for (Map.Entry<String, BigDecimal> entry : totals.entrySet()) {
            YearMonth period = start.plusMonths(index++);
            points.add(new DashboardPointDto(
                period.getMonth().getDisplayName(TextStyle.SHORT, FRENCH),
                entry.getValue().setScale(0, RoundingMode.HALF_UP).doubleValue()
            ));
        }
        return points;
    }

    private List<DashboardPointDto> buildDepartmentBreakdown(List<Employe> employees) {
        Map<String, Long> grouped = employees.stream()
            .filter(employee -> employee.getService() != null)
            .collect(
                LinkedHashMap::new,
                (map, employee) -> map.merge(employee.getService().getNom(), 1L, Long::sum),
                LinkedHashMap::putAll
            );

        if (grouped.isEmpty()) {
            return List.of();
        }

        return grouped.entrySet()
            .stream()
            .map(entry -> new DashboardPointDto(entry.getKey(), entry.getValue()))
            .toList();
    }

    private List<RecentActivityDto> buildRecentActivities(List<Conge> leaves, List<Presence> presences) {
        List<RecentActivityDto> activities = new ArrayList<>();

        leaves.stream()
            .sorted(Comparator.comparing(Conge::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
            .limit(4)
            .forEach(leave -> activities.add(new RecentActivityDto(
                "conge-" + leave.getId(),
                leave.getEmploye().getPrenom() + " " + leave.getEmploye().getNom(),
                "Demande de congé " + leave.getStatut().name().toLowerCase(FRENCH).replace('_', ' '),
                leave.getCreatedAt() != null ? leave.getCreatedAt() : OffsetDateTime.now(),
                leave.getEmploye().getPhotoUrl()
            )));

        presences.stream()
            .sorted(Comparator.comparing(Presence::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
            .limit(4)
            .forEach(presence -> activities.add(new RecentActivityDto(
                "presence-" + presence.getId(),
                presence.getEmploye().getPrenom() + " " + presence.getEmploye().getNom(),
                "Pointage " + presence.getStatut().name().toLowerCase(FRENCH),
                presence.getCreatedAt() != null ? presence.getCreatedAt() : OffsetDateTime.now(),
                presence.getEmploye().getPhotoUrl()
            )));

        return activities.stream()
            .sorted(Comparator.comparing(RecentActivityDto::timestamp).reversed())
            .limit(6)
            .toList();
    }

    @Transactional(readOnly = true)
    public EnhancedDashboardResponse getEnhancedDashboard() {
        LocalDate today = LocalDate.now();
        List<Employe> employees = employeRepository.findAll();
        List<Conge> leaves = congeRepository.findAll();
        List<Presence> monthlyPresences = presenceRepository.findByDateBetweenOrderByDateAsc(
            YearMonth.now().minusMonths(5).atDay(1), today);

        // KPI Summary
        long totalEmployees = employees.stream().filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut())).count();
        long presentToday = presenceRepository.countByDateAndStatut(today, StatutPresence.PRESENT);
        double attendanceRate = totalEmployees == 0 ? 0 : (presentToday * 100d) / totalEmployees;
        long pendingLeaves = congeRepository.countByStatut(StatutConge.EN_ATTENTE);
        BigDecimal payrollMass = employees.stream()
            .filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut()))
            .map(Employe::getSalaireBrutBase)
            .filter(java.util.Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Charts
        List<DashboardPointDto> attendanceEvolution = buildAttendanceEvolution(monthlyPresences);
        List<DashboardPointDto> departmentBreakdown = buildDepartmentBreakdown(employees);

        // Leave requests
        List<LeaveRequestDto> recentLeaves = buildRecentLeaveRequests(leaves);

        // Birthdays
        List<BirthdayDto> birthdays = buildUpcomingBirthdays(employees);

        // Quick stats
        QuickStatsDto quickStats = buildQuickStats(employees);

        // Payroll breakdown
        List<DashboardPointDto> payrollBreakdown = buildPayrollBreakdown();

        return new EnhancedDashboardResponse(
            totalEmployees,
            Math.round(attendanceRate * 10.0) / 10.0,
            pendingLeaves,
            payrollMass.doubleValue(),
            attendanceEvolution,
            departmentBreakdown,
            recentLeaves,
            birthdays,
            quickStats,
            payrollBreakdown
        );
    }

    /** Nombre de pointages « présent » par mois sur les 6 derniers mois (libellés réels). */
    private List<DashboardPointDto> buildAttendanceEvolution(List<Presence> presences) {
        YearMonth start = YearMonth.now().minusMonths(5);
        Map<YearMonth, Long> monthly = new LinkedHashMap<>();
        for (int i = 0; i < 6; i++) {
            monthly.put(start.plusMonths(i), 0L);
        }
        for (Presence presence : presences) {
            if (presence.getStatut() == StatutPresence.PRESENT) {
                monthly.computeIfPresent(YearMonth.from(presence.getDate()), (k, v) -> v + 1);
            }
        }
        return monthly.entrySet().stream()
            .map(e -> new DashboardPointDto(
                e.getKey().getMonth().getDisplayName(TextStyle.SHORT, FRENCH),
                e.getValue().doubleValue()))
            .toList();
    }

    private List<LeaveRequestDto> buildRecentLeaveRequests(List<Conge> leaves) {
        return leaves.stream()
            .filter(l -> l.getStatut() != StatutConge.REFUSE)
            .sorted(Comparator.comparing(Conge::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
            .limit(4)
            .map(l -> new LeaveRequestDto(
                l.getId(),
                l.getEmploye().getPrenom() + " " + l.getEmploye().getNom(),
                l.getEmploye().getPhotoUrl(),
                l.getDateDebut(),
                l.getDateFin(),
                l.getStatut().name(),
                l.getCreatedAt() != null ? l.getCreatedAt() : OffsetDateTime.now()
            ))
            .toList();
    }

    private List<BirthdayDto> buildUpcomingBirthdays(List<Employe> employees) {
        LocalDate today = LocalDate.now();
        return employees.stream()
            .filter(e -> e.getDateNaissance() != null)
            .map(e -> {
                LocalDate nextBirthday = e.getDateNaissance().withYear(today.getYear());
                if (nextBirthday.isBefore(today)) {
                    nextBirthday = nextBirthday.plusYears(1);
                }
                int daysUntil = (int) java.time.temporal.ChronoUnit.DAYS.between(today, nextBirthday);
                return new BirthdayDto(e.getId(), e.getPrenom() + " " + e.getNom(), e.getPhotoUrl(), 
                    e.getDateNaissance(), daysUntil);
            })
            .filter(b -> b.daysUntilBirthday() <= 30)
            .sorted(Comparator.comparingInt(BirthdayDto::daysUntilBirthday))
            .limit(4)
            .toList();
    }

    private QuickStatsDto buildQuickStats(List<Employe> employees) {
        long activeContracts = employees.stream().filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut())).count();
        long probationary = employees.stream()
            .filter(e -> "ACTIF".equalsIgnoreCase(e.getStatut()) && e.getDateEmbauche() != null && 
                e.getDateEmbauche().plusMonths(3).isAfter(LocalDate.now()))
            .count();
        long departures = employees.stream().filter(e -> "ARCHIVE".equalsIgnoreCase(e.getStatut())).count();
        long trainings = formationRepository.findByStatutOrderByDateDebutDesc("EN_COURS").size();

        long cdi = employees.stream()
            .filter(e -> e.getTypeContrat() == TypeContrat.CDI)
            .count();
        long cdd = employees.stream()
            .filter(e -> e.getTypeContrat() == TypeContrat.CDD)
            .count();
        long internship = employees.stream()
            .filter(e -> e.getTypeContrat() == TypeContrat.STAGE)
            .count();

        return new QuickStatsDto(activeContracts, probationary, departures, trainings, cdi, cdd, internship);
    }

    /**
     * Ventilation issue des fiches de paie de la dernière période calculée
     * (aucune estimation : liste vide si aucune paie n'a été calculée).
     */
    private List<DashboardPointDto> buildPayrollBreakdown() {
        YearMonth period = YearMonth.now();
        List<FichePaie> fiches = List.of();
        for (int i = 0; i < 12 && fiches.isEmpty(); i++) {
            fiches = fichePaieRepository.findByPeriodeOrderByEmployeNomAsc(FichePaie.formatPeriode(period.minusMonths(i)));
        }
        if (fiches.isEmpty()) {
            return List.of();
        }
        BigDecimal brut = sum(fiches, FichePaie::getSalaireBrut);
        BigDecimal indemnites = sum(fiches, FichePaie::getIndemnites);
        BigDecimal cotisations = sum(fiches, FichePaie::getCotisations);
        BigDecimal impots = sum(fiches, FichePaie::getImpots);
        BigDecimal net = sum(fiches, FichePaie::getSalaireNet);
        return List.of(
            new DashboardPointDto("Salaire brut", brut.doubleValue()),
            new DashboardPointDto("Indemnités", indemnites.doubleValue()),
            new DashboardPointDto("Cotisations sociales", cotisations.doubleValue()),
            new DashboardPointDto("Impôts", impots.doubleValue()),
            new DashboardPointDto("Net à payer", net.doubleValue())
        );
    }

    private static BigDecimal sum(List<FichePaie> fiches, java.util.function.Function<FichePaie, BigDecimal> getter) {
        return fiches.stream().map(getter).filter(java.util.Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
