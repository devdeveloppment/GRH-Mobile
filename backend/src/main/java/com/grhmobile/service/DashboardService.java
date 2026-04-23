package com.grhmobile.service;

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
import com.grhmobile.entity.Conge;
import com.grhmobile.entity.Employe;
import com.grhmobile.entity.FichePaie;
import com.grhmobile.entity.Presence;
import com.grhmobile.enums.StatutConge;
import com.grhmobile.enums.StatutPresence;
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

    public DashboardService(
        EmployeRepository employeRepository,
        PresenceRepository presenceRepository,
        CongeRepository congeRepository,
        FichePaieRepository fichePaieRepository
    ) {
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

        BigDecimal payrollMass = employees.stream()
            .map(Employe::getSalaireBrutBase)
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
            buildPayrollEvolution(employees),
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

    private List<DashboardPointDto> buildPayrollEvolution(List<Employe> employees) {
        List<DashboardPointDto> points = new ArrayList<>();
        BigDecimal base = employees.stream().map(Employe::getSalaireBrutBase).reduce(BigDecimal.ZERO, BigDecimal::add);
        for (int i = 5; i >= 0; i--) {
            YearMonth period = YearMonth.now().minusMonths(i);
            BigDecimal adjusted = base.multiply(BigDecimal.valueOf(0.92 + (5 - i) * 0.02));
            points.add(new DashboardPointDto(
                period.getMonth().getDisplayName(TextStyle.SHORT, FRENCH),
                adjusted.setScale(0, RoundingMode.HALF_UP).doubleValue()
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
}
