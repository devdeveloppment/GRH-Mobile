import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/core/providers/notification_provider.dart';
import 'package:grh_mobile/core/providers/service_provider.dart';
import 'package:grh_mobile/shared/models/utilisateur.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/grh_sidebar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

class AdminConsoleScreen extends ConsumerStatefulWidget {
  const AdminConsoleScreen({super.key, required this.sectionTitle});

  final String sectionTitle;

  @override
  ConsumerState<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends ConsumerState<AdminConsoleScreen> {
  String get _pageTitle => switch (widget.sectionTitle) {
        'Utilisateurs'  => 'Gestion des utilisateurs',
        'Rôles'         => 'Rôles & permissions',
        'Paramètres'    => 'Paramètres système',
        _               => 'Tableau de bord',
      };

  String get _currentRoute => switch (widget.sectionTitle) {
        'Utilisateurs'  => AppRoutes.adminUsers,
        'Rôles'         => AppRoutes.adminRoles,
        'Paramètres'    => AppRoutes.adminSettings,
        _               => AppRoutes.adminDashboard,
      };

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isWide
          ? null
          : Drawer(
              child: GrhSidebar(
                currentRoute: _currentRoute,
                role: auth.role!,
                isDrawer: true,
              ),
            ),
      body: Row(
        children: [
          if (isWide && auth.role != null)
            GrhSidebar(currentRoute: _currentRoute, role: auth.role!),
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (ctx) => _AdminTopBar(
                    userName: auth.user?.fullName ?? 'Admin GRH',
                    userRole: 'Administrateur',
                    onMenuTap: isWide ? null : () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pageTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionContent(isWide),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(bool isWide) {
    return switch (widget.sectionTitle) {
      'Utilisateurs' => const _UsersSection(),
      'Rôles'        => const _RolesSection(),
      'Paramètres'   => const _SettingsSection(),
      _ => _DashboardSection(isWide: isWide),
    };
  }

}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar({
    required this.userName,
    required this.userRole,
    this.onMenuTap,
  });

  final String userName;
  final String userRole;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
        notificationNotifierProvider.select((n) => n.unreadCount));
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.text1),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (onMenuTap != null) const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search_rounded,
                            color: AppColors.textHint, size: 18),
                      ),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un employé, un service…',
                            hintStyle: TextStyle(
                                color: AppColors.textHint, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: 13, color: AppColors.text1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.text1, size: 22),
                onPressed: () => context.go(AppRoutes.notifications),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1),
                  ),
                  Text(
                    userRole,
                    style: const TextStyle(fontSize: 11, color: AppColors.text2),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.text2, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dashboard section connectée au backend ────────────────────────────────────

class _DashboardSection extends ConsumerWidget {
  const _DashboardSection({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardNotifierProvider);
    final s = dashboard.summary;

    String _fmt(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} k';
      return v.toStringAsFixed(0);
    }

    final cards = [
      _KpiCard(
        label: 'Employés',
        value: s != null ? '${s.totalEmployees}' : '—',
        trend: s != null ? '${s.presentToday} présents aujourd\'hui' : 'Chargement…',
        trendUp: null,
        icon: Icons.people_outline_rounded,
        color: AppColors.primary,
      ),
      _KpiCard(
        label: 'Taux de présence',
        value: s != null ? '${s.attendanceRate.toStringAsFixed(0)}%' : '—',
        trend: s != null ? '${s.presentToday} / ${s.totalEmployees}' : 'Chargement…',
        trendUp: true,
        icon: Icons.fact_check_outlined,
        color: AppColors.success,
      ),
      _KpiCard(
        label: 'Demandes de congés',
        value: s != null ? '${s.pendingLeaves}' : '—',
        trend: 'En attente de validation',
        trendUp: null,
        trendColor: AppColors.warning,
        icon: Icons.event_note_outlined,
        color: AppColors.warning,
      ),
      _KpiCard(
        label: 'Masse salariale',
        value: s != null ? _fmt(s.payrollMass) : '—',
        valueSuffix: 'FCFA',
        trend: 'Ce mois',
        trendUp: null,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.accent,
      ),
    ];

    Widget kpiRow;
    if (isWide) {
      kpiRow = Row(
        children: cards
            .map((c) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 14), child: c)))
            .toList()
          ..last = Expanded(child: cards.last),
      );
    } else {
      kpiRow = Column(
        children: cards
            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c))
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kpiRow,
        const SizedBox(height: 20),
        if (isWide) const _WideBody() else const _NarrowBody(),
      ],
    );
  }
}

// ── KPI row (statique, conservé pour référence) ────────────────────────────────


class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
    this.trendUp,
    this.trendColor,
    this.valueSuffix,
  });

  final String label;
  final String value;
  final String? valueSuffix;
  final String trend;
  final bool? trendUp;
  final Color? trendColor;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color tc = trendColor ??
        (trendUp == null
            ? AppColors.text2
            : trendUp!
                ? AppColors.success
                : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.text2)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1)),
                    if (valueSuffix != null) ...[
                      const SizedBox(width: 4),
                      Text(valueSuffix!,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.text2)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(trend,
                    style: TextStyle(
                        fontSize: 11,
                        color: tc,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wide layout ───────────────────────────────────────────────────────────────

class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 55, child: _PresenceLineChart()),
                  const SizedBox(width: 14),
                  const Expanded(flex: 45, child: _DepartmentDonut()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: _PayrollSummary()),
                  SizedBox(width: 14),
                  Expanded(child: _QuickStatsSection()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const SizedBox(width: 280, child: _RightPanel()),
      ],
    );
  }
}

class _NarrowBody extends StatelessWidget {
  const _NarrowBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PresenceLineChart(),
        SizedBox(height: 14),
        _DepartmentDonut(),
        SizedBox(height: 14),
        _RightPanel(),
        SizedBox(height: 14),
        _PayrollSummary(),
        SizedBox(height: 14),
        _QuickStatsSection(),
      ],
    );
  }
}

// ── Évolution des présences (line chart) ─────────────────────────────────────

class _PresenceLineChart extends StatelessWidget {
  const _PresenceLineChart();

  static const _months = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'
  ];
  static const _values = [
    30.0, 55.0, 50.0, 55.0, 70.0, 65.0,
    65.0, 70.0, 70.0, 75.0, 80.0, 90.0
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Évolution des présences',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Row(
                  children: [
                    Text('Cette année',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.text2)),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14, color: AppColors.text2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.text2),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _months[i],
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.text2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < _values.length; i++)
                        FlSpot(i.toDouble(), _values[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.accent,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withOpacity(0.07),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Répartition par département (donut) ───────────────────────────────────────

class _DepartmentDonut extends StatelessWidget {
  const _DepartmentDonut();

  static const _sections = [
    (label: 'Informatique', value: 25.0, color: AppColors.primary),
    (label: 'Finance', value: 20.0, color: Color(0xFF22856A)),
    (label: 'Commercial', value: 20.0, color: Color(0xFF2D7FF9)),
    (label: 'Ressources Humaines', value: 15.0, color: AppColors.accent),
    (label: 'Autres', value: 20.0, color: AppColors.text2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition par département',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 44,
                      sectionsSpace: 2,
                      sections: [
                        for (final s in _sections)
                          PieChartSectionData(
                            color: s.color,
                            value: s.value,
                            title: '${s.value.toInt()}%',
                            radius: 46,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _sections
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: Text(
                                s.label,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.text2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s.value.toInt()}%',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text1),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Résumé de la paie ─────────────────────────────────────────────────────────

class _PayrollSummary extends StatelessWidget {
  const _PayrollSummary();

  static const _items = [
    (label: 'Salaire de base', amount: '15 000 000 FCFA', color: AppColors.primary),
    (label: 'Primes', amount: '5 500 000 FCFA', color: Color(0xFF2D7FF9)),
    (label: 'Indemnités', amount: '3 200 000 FCFA', color: AppColors.accent),
    (label: 'Charges sociales', amount: '2 080 000 FCFA', color: AppColors.text2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résumé de la paie (Mai 2024)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(
                              color: AppColors.primary,
                              value: 58,
                              title: '',
                              radius: 30),
                          PieChartSectionData(
                              color: const Color(0xFF2D7FF9),
                              value: 21,
                              title: '',
                              radius: 30),
                          PieChartSectionData(
                              color: AppColors.accent,
                              value: 12,
                              title: '',
                              radius: 30),
                          PieChartSectionData(
                              color: AppColors.text2,
                              value: 9,
                              title: '',
                              radius: 30),
                        ],
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('25 780 000',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text1)),
                        Text('FCFA',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.text2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.label,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.text2)),
                              ),
                              Text(item.amount,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text1)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net à payer',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                Text('25 780 000 FCFA',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Statistiques rapides + contrats ──────────────────────────────────────────

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistiques rapides',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: const [
                  _MiniStatCard(
                    label: 'Contrats actifs',
                    value: '210',
                    icon: Icons.assignment_outlined,
                    color: Color(0xFF2D7FF9),
                  ),
                  _MiniStatCard(
                    label: 'Départs ce mois',
                    value: '3',
                    icon: Icons.person_remove_outlined,
                    color: AppColors.error,
                  ),
                  _MiniStatCard(
                    label: "Période d'essai",
                    value: '14',
                    icon: Icons.hourglass_empty_outlined,
                    color: AppColors.warning,
                  ),
                  _MiniStatCard(
                    label: 'Formations en cours',
                    value: '8',
                    icon: Icons.school_outlined,
                    color: Color(0xFF22856A),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Répartition par type de contrat',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1)),
              const SizedBox(height: 14),
              _ContractBar(label: 'CDI', percent: 0.60, color: AppColors.primary),
              const SizedBox(height: 10),
              _ContractBar(label: 'CDD', percent: 0.30, color: AppColors.accent),
              const SizedBox(height: 10),
              _ContractBar(
                  label: 'Stage',
                  percent: 0.10,
                  color: const Color(0xFF2D7FF9)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.text2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractBar extends StatelessWidget {
  const _ContractBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text1)),
            Text('${(percent * 100).toInt()}%',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.text2)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: AppColors.surface,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Right panel ───────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionsSection(),
        const SizedBox(height: 16),
        _RecentLeavesSection(),
        const SizedBox(height: 16),
        _BirthdaysSection(),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                icon: Icons.add_rounded,
                label: 'Ajouter un employé',
                bg: AppColors.accent,
                onTap: () => context.go(AppRoutes.employees),
              ),
              _QuickActionCard(
                icon: Icons.person_add_alt_outlined,
                label: 'Nouvelle demande de congé',
                bg: const Color(0xFF22856A),
                onTap: () => context.go(AppRoutes.conges),
              ),
              _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Générer bulletin de paie',
                bg: const Color(0xFF2D7FF9),
                onTap: () => context.go(AppRoutes.paie),
              ),
              _QuickActionCard(
                icon: Icons.bar_chart_rounded,
                label: 'Voir les rapports',
                bg: const Color(0xFF7C3AED),
                onTap: () => context.go(AppRoutes.rapports),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.bg,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: bg),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demandes de congé récentes ────────────────────────────────────────────────

class _RecentLeavesSection extends StatelessWidget {
  const _RecentLeavesSection();

  static const _leaves = [
    (
      name: 'Aba Atsan',
      type: 'Congé annuel',
      dates: '15/06/2024 → 20/06/2024',
      status: 'En attente',
      badgeType: 'pending',
    ),
    (
      name: 'Mensah Aboouie',
      type: 'Congé exceptionnel',
      dates: '10/06/2024 → 11/06/2024',
      status: 'Approuvé',
      badgeType: 'active',
    ),
    (
      name: 'Djibounou M. Alové',
      type: 'Congé annuel',
      dates: '20/06/2024 → 27/06/2024',
      status: 'En attente',
      badgeType: 'pending',
    ),
    (
      name: 'Tchalla Esso',
      type: 'Congé annuel',
      dates: '01/07/2024 → 05/07/2024',
      status: 'Approuvé',
      badgeType: 'active',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Demandes de congé récentes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1)),
              TextButton(
                onPressed: () => context.go(AppRoutes.conges),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._leaves.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  EmployeeAvatar(name: item.name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${item.type} • ${item.dates}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.text2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusBadge(label: item.status, type: item.badgeType),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Anniversaires du mois ─────────────────────────────────────────────────────

class _BirthdaysSection extends StatelessWidget {
  const _BirthdaysSection();

  static const _birthdays = [
    (name: 'Koffi A. Jean', date: '12 Juin'),
    (name: 'Aba Atsan', date: '18 Juin'),
    (name: 'Mensah Aboouie', date: '25 Juin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Anniversaires du mois',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1)),
              TextButton(
                onPressed: () => context.go(AppRoutes.employees),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._birthdays.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  EmployeeAvatar(name: item.name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text1)),
                        Text(item.date,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.card_giftcard_outlined,
                        color: AppColors.accent, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION : Gestion des utilisateurs
// ══════════════════════════════════════════════════════════════════════════════

class _UsersSection extends ConsumerStatefulWidget {
  const _UsersSection();
  @override
  ConsumerState<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<_UsersSection> {
  String _query = '';

  Future<void> _showCreateDialog() async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'EMPLOYEE';
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvel utilisateur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom complet', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                    labelText: 'Rôle', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrateur')),
                  DropdownMenuItem(value: 'RH_MANAGER', child: Text('RH Manager')),
                  DropdownMenuItem(value: 'DIRECTION', child: Text('Direction')),
                  DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employé')),
                ],
                onChanged: (v) => setS(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty) {
                  setS(() => error = 'Veuillez remplir tous les champs.');
                  return;
                }
                final ok = await ref.read(adminNotifierProvider).createUser(
                      email: emailCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      role: selectedRole,
                    );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                } else {
                  setS(() =>
                      error = ref.read(adminNotifierProvider).errorMessage ??
                          'Erreur lors de la création.');
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
    nameCtrl.dispose();
  }

  Future<void> _showEditDialog(Utilisateur u) async {
    final nameCtrl = TextEditingController(text: u.fullName);
    final emailCtrl = TextEditingController(text: u.email);
    String selectedRole = u.role.apiValue;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Modifier l\'utilisateur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom complet', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                    labelText: 'Rôle', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrateur')),
                  DropdownMenuItem(value: 'RH_MANAGER', child: Text('RH Manager')),
                  DropdownMenuItem(value: 'DIRECTION', child: Text('Direction')),
                  DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employé')),
                ],
                onChanged: (v) => setS(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                final ok = await ref.read(adminNotifierProvider).updateUser(
                      userId: u.id,
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      role: selectedRole,
                    );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                } else {
                  setS(() =>
                      error = ref.read(adminNotifierProvider).errorMessage ??
                          'Erreur lors de la mise à jour.');
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(adminNotifierProvider);
    final filtered = prov.users
        .where((u) =>
            _query.isEmpty ||
            u.fullName.toLowerCase().contains(_query.toLowerCase()) ||
            u.email.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textHint),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un utilisateur…',
                          hintStyle:
                              TextStyle(color: AppColors.textHint, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Nouvel utilisateur'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (prov.isLoading && filtered.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ))
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 44),
                      Expanded(
                          flex: 3,
                          child: Text('Utilisateur',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2))),
                      Expanded(
                          flex: 2,
                          child: Text('Email',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2))),
                      Expanded(
                          flex: 2,
                          child: Text('Rôle',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2))),
                      SizedBox(
                          width: 80,
                          child: Text('Statut',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2))),
                      SizedBox(
                          width: 80,
                          child: Text('Actions',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2))),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aucun utilisateur trouvé.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.text2)),
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final i = entry.key;
                    final u = entry.value;
                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              _UserAvatar(name: u.fullName),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Text(u.fullName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text1)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(u.email,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.text2),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: _RoleBadge(role: u.role.apiValue)),
                              SizedBox(
                                width: 80,
                                child: StatusBadge(
                                  label: u.actif ? 'Actif' : 'Inactif',
                                  type: u.actif ? 'active' : 'rejected',
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Row(
                                  children: [
                                    _IconBtn(
                                      icon: Icons.edit_outlined,
                                      color: AppColors.accent,
                                      onTap: () => _showEditDialog(u),
                                    ),
                                    const SizedBox(width: 4),
                                    _IconBtn(
                                      icon: u.actif
                                          ? Icons.block_outlined
                                          : Icons.check_circle_outline,
                                      color: u.actif
                                          ? AppColors.error
                                          : AppColors.success,
                                      onTap: () async {
                                        await ref
                                            .read(adminNotifierProvider)
                                            .toggleUser(u.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary,
      child: Text(letter, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'ADMIN'      => ('Admin', AppColors.primary),
      'RH_MANAGER' => ('RH Manager', const Color(0xFF22856A)),
      'DIRECTION'  => ('Direction', const Color(0xFF2D7FF9)),
      _            => ('Employé', AppColors.text2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION : Rôles & permissions
// ══════════════════════════════════════════════════════════════════════════════

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  static const _roles = [
    (
      role: 'Administrateur',
      icon: Icons.shield_outlined,
      color: AppColors.primary,
      description: 'Accès total à toutes les fonctionnalités de la plateforme.',
      permissions: ['Gestion des utilisateurs', 'Configuration système', 'Tous les modules RH', 'Rapports exécutifs', 'Données sensibles'],
      count: 1,
    ),
    (
      role: 'RH Manager',
      icon: Icons.manage_accounts_outlined,
      color: Color(0xFF22856A),
      description: 'Gestion complète des employés, congés, présences et paie.',
      permissions: ['Liste & dossiers employés', 'Validation des congés', 'Suivi des présences', 'Calcul et bulletins de paie', 'Rapports RH'],
      count: 2,
    ),
    (
      role: 'Direction',
      icon: Icons.query_stats_outlined,
      color: Color(0xFF2D7FF9),
      description: 'Lecture seule sur les indicateurs stratégiques et rapports.',
      permissions: ['Dashboard exécutif', 'Rapports et exports', 'KPI globaux', 'Masse salariale'],
      count: 3,
    ),
    (
      role: 'Employé',
      icon: Icons.badge_outlined,
      color: AppColors.text2,
      description: 'Accès à son propre espace : profil, congés et bulletins.',
      permissions: ['Profil personnel', 'Demande de congé', 'Suivi présences', 'Bulletins de paie'],
      count: 42,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: _roles.map((r) => _RoleCard(r: r)).toList(),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.r});
  final ({String role, IconData icon, Color color, String description, List<String> permissions, int count}) r;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 1200 ? (width - 210 - 48 - 42) / 4 : width >= 900 ? (width - 210 - 48 - 14) / 2 : double.infinity;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: r.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.icon, color: r.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.role,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
                      Text('${r.count} utilisateur${r.count > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(r.description, style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.4)),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            const SizedBox(height: 12),
            ...r.permissions.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(p, style: const TextStyle(fontSize: 11, color: AppColors.text1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.adminRoles),
                style: OutlinedButton.styleFrom(
                  foregroundColor: r.color,
                  side: BorderSide(color: r.color.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Modifier les permissions', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION : Paramètres système
// ══════════════════════════════════════════════════════════════════════════════

class _SettingsSection extends ConsumerStatefulWidget {
  const _SettingsSection();

  @override
  ConsumerState<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends ConsumerState<_SettingsSection> {
  @override
  void initState() {
    super.initState();
    // Load current settings from API on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = ref.read(adminNotifierProvider);
      try {
        final api = ref.read(apiServiceProvider);
        final resp = await api.get<Map<String, dynamic>>('/admin/settings');
        final data = resp.data?['settings'] as Map<String, dynamic>? ?? {};
        final bools = data.map((k, v) => MapEntry(k, v == true || v == 'true'));
        prov.settings.addAll(bools);
        // ignore: invalid_use_of_protected_member
        prov.notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prov = ref.read(adminNotifierProvider);
    final updated = Map<String, bool>.from(prov.settings)..[key] = value;
    await prov.updateSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(adminNotifierProvider);
    final s = prov.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          title: 'Sécurité & authentification',
          children: [
            _SettingRow(
              icon: Icons.verified_user_outlined,
              title: 'Authentification SSO / Azure AD',
              subtitle: "Renforce le contrôle d'accès pour les comptes d'entreprise.",
              value: s['SSO'] ?? false,
              onChanged: (v) => _toggle('SSO', v),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _SettingRow(
              icon: Icons.notifications_outlined,
              title: 'Notifications administrateur',
              subtitle: 'Alertes sur les incidents, exports et erreurs critiques.',
              value: s['NOTIFICATIONS'] ?? true,
              onChanged: (v) => _toggle('NOTIFICATIONS', v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Infrastructure',
          children: [
            _InfoRow(
              icon: Icons.cloud_outlined,
              iconColor: const Color(0xFF2D7FF9),
              title: 'Hébergement AWS',
              lines: ['Région : eu-west-3 (Paris)', 'Services : ECS Fargate · RDS PostgreSQL · CloudFront · WAF'],
              action: _HealthCheckButton(),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _InfoRow(
              icon: Icons.storage_outlined,
              iconColor: AppColors.success,
              title: 'Base de données PostgreSQL',
              lines: ['Connexions actives : 4 / 10', 'Dernier backup : aujourd\'hui à 03:00'],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Identifiants de démonstration',
          children: [
            _DemoAccount(role: 'Administrateur', email: 'admin@grh-mobile.com', password: 'Admin@12345', color: AppColors.primary),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _DemoAccount(role: 'RH Manager', email: 'rh@grh-mobile.com', password: 'ChangeMe@123', color: const Color(0xFF22856A)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _DemoAccount(role: 'Direction', email: 'direction@grh-mobile.com', password: 'ChangeMe@123', color: const Color(0xFF2D7FF9)),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _DemoAccount(role: 'Employé', email: 'employee@grh-mobile.com', password: 'ChangeMe@123', color: AppColors.text2),
          ],
        ),
      ],
    );
  }
}

class _HealthCheckButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HealthCheckButton> createState() => _HealthCheckButtonState();
}

class _HealthCheckButtonState extends ConsumerState<_HealthCheckButton> {
  bool _loading = false;
  String? _status;

  Future<void> _check() async {
    setState(() { _loading = true; _status = null; });
    try {
      final api = ref.read(apiServiceProvider);
      await api.get<dynamic>('/actuator/health');
      setState(() => _status = 'ok');
    } catch (_) {
      setState(() => _status = 'error');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _status == 'ok'
        ? AppColors.success
        : _status == 'error'
            ? AppColors.error
            : AppColors.primary;
    return OutlinedButton(
      onPressed: _loading ? null : _check,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: _loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _status == 'ok'
                  ? 'En ligne ✓'
                  : _status == 'error'
                      ? 'Hors ligne ✗'
                      : 'Vérifier',
              style: const TextStyle(fontSize: 12),
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.iconColor, required this.title, required this.lines, this.action});
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                ...lines.map((l) => Text(l, style: const TextStyle(fontSize: 11, color: AppColors.text2))),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _DemoAccount extends StatelessWidget {
  const _DemoAccount({required this.role, required this.email, required this.password, required this.color});
  final String role;
  final String email;
  final String password;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
            child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(email, style: const TextStyle(fontSize: 12, color: AppColors.text2))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Text(password, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.text1)),
          ),
        ],
      ),
    );
  }
}

