import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:grh_mobile/shared/widgets/temporary_password_dialog.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/constants/app_routes.dart';
import 'package:grh_mobile/core/providers/admin_provider.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/dashboard_provider.dart';
import 'package:grh_mobile/core/providers/notification_provider.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';
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
      drawer: isWide || auth.role == null
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

class _WideBody extends ConsumerWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(enhancedDashboardProvider).when(
          loading: () => const _SectionLoading(),
          error: (e, _) => _SectionError(onRetry: () => ref.invalidate(enhancedDashboardProvider)),
          data: (data) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 55, child: _PresenceLineChart(points: data.attendanceEvolution)),
                        const SizedBox(width: 14),
                        Expanded(flex: 45, child: _DepartmentDonut(points: data.departmentBreakdown)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _PayrollSummary(points: data.payrollBreakdown)),
                        const SizedBox(width: 14),
                        Expanded(child: _QuickStatsSection(stats: data.quickStats)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(width: 280, child: _RightPanel(data: data)),
            ],
          ),
        );
  }
}

class _NarrowBody extends ConsumerWidget {
  const _NarrowBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(enhancedDashboardProvider).when(
          loading: () => const _SectionLoading(),
          error: (e, _) => _SectionError(onRetry: () => ref.invalidate(enhancedDashboardProvider)),
          data: (data) => Column(
            children: [
              _PresenceLineChart(points: data.attendanceEvolution),
              const SizedBox(height: 14),
              _DepartmentDonut(points: data.departmentBreakdown),
              const SizedBox(height: 14),
              _RightPanel(data: data),
              const SizedBox(height: 14),
              _PayrollSummary(points: data.payrollBreakdown),
              const SizedBox(height: 14),
              _QuickStatsSection(stats: data.quickStats),
            ],
          ),
        );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.text2),
          const SizedBox(height: 8),
          const Text('Impossible de charger les indicateurs.',
              style: TextStyle(fontSize: 12, color: AppColors.text2)),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Carte blanche commune aux sections du tableau de bord.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1));
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.text2)),
      ),
    );
  }
}

String _fcfa(double value) => '${NumberFormat.decimalPattern('fr').format(value.round())} FCFA';

const _palette = [
  AppColors.primary,
  Color(0xFF22856A),
  Color(0xFF2D7FF9),
  AppColors.accent,
  Color(0xFF7C3AED),
  AppColors.text2,
];

// ── Évolution des présences (line chart) ─────────────────────────────────────

class _PresenceLineChart extends StatelessWidget {
  const _PresenceLineChart({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.value > 0);
    final maxValue = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    final maxY = maxValue <= 0 ? 10.0 : (maxValue * 1.2).ceilToDouble();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Pointages « présent » — 6 derniers mois'),
          const SizedBox(height: 20),
          if (!hasData)
            const _EmptyHint('Aucun pointage enregistré sur la période.')
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.text2)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(points[i].label,
                                style: const TextStyle(fontSize: 10, color: AppColors.text2)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.accent,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.accent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withValues(alpha: 0.07),
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

// ── Répartition par service (donut) ──────────────────────────────────────────

class _DepartmentDonut extends StatelessWidget {
  const _DepartmentDonut({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (s, p) => s + p.value);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Répartition des effectifs par service'),
          const SizedBox(height: 20),
          if (total <= 0)
            const _EmptyHint('Aucun employé rattaché à un service.')
          else
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
                          for (int i = 0; i < points.length; i++)
                            PieChartSectionData(
                              color: _palette[i % _palette.length],
                              value: points[i].value,
                              title: '${(points[i].value * 100 / total).round()}%',
                              radius: 46,
                              titleStyle: const TextStyle(
                                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
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
                  children: [
                    for (int i = 0; i < points.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: _palette[i % _palette.length], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: Text(points[i].label,
                                  style: const TextStyle(fontSize: 11, color: AppColors.text2),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 4),
                            Text('${points[i].value.toInt()}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text1)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Résumé de la paie (dernière période calculée) ────────────────────────────

class _PayrollSummary extends StatelessWidget {
  const _PayrollSummary({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final net = points.where((p) => p.label == 'Net à payer').fold<double>(0, (s, p) => s + p.value);
    final parts = points.where((p) => p.label != 'Net à payer').toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Résumé de la dernière paie calculée'),
          const SizedBox(height: 16),
          if (points.isEmpty)
            const _EmptyHint('Aucune paie calculée pour le moment.\nLancez le calcul depuis le module Paie.')
          else ...[
            for (int i = 0; i < parts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(parts[i].label, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                    ),
                    Text(_fcfa(parts[i].value),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net à payer',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Text(_fcfa(net),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Statistiques rapides + contrats ──────────────────────────────────────────

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({required this.stats});

  final QuickStats stats;

  @override
  Widget build(BuildContext context) {
    final totalContracts = stats.cdiCount + stats.cddCount + stats.internshipCount;
    double share(int n) => totalContracts == 0 ? 0 : n / totalContracts;

    return Column(
      children: [
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Statistiques rapides'),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  _MiniStatCard(
                    label: 'Employés actifs',
                    value: '${stats.activeContracts}',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF2D7FF9),
                  ),
                  _MiniStatCard(
                    label: 'Employés archivés',
                    value: '${stats.departures}',
                    icon: Icons.person_remove_outlined,
                    color: AppColors.error,
                  ),
                  _MiniStatCard(
                    label: 'Embauchés < 3 mois',
                    value: '${stats.probationaryPeriod}',
                    icon: Icons.hourglass_empty_outlined,
                    color: AppColors.warning,
                  ),
                  _MiniStatCard(
                    label: 'Formations en cours',
                    value: '${stats.trainingInProgress}',
                    icon: Icons.school_outlined,
                    color: const Color(0xFF22856A),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('Répartition par type de contrat'),
              const SizedBox(height: 14),
              if (totalContracts == 0)
                const _EmptyHint('Aucun contrat CDI, CDD ou stage enregistré.')
              else ...[
                _ContractBar(label: 'CDI (${stats.cdiCount})', percent: share(stats.cdiCount), color: AppColors.primary),
                const SizedBox(height: 10),
                _ContractBar(label: 'CDD (${stats.cddCount})', percent: share(stats.cddCount), color: AppColors.accent),
                const SizedBox(height: 10),
                _ContractBar(
                    label: 'Stage (${stats.internshipCount})',
                    percent: share(stats.internshipCount),
                    color: const Color(0xFF2D7FF9)),
              ],
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
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
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
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: AppColors.text2),
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
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text1)),
            Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
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
  const _RightPanel({required this.data});

  final EnhancedDashboard data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _QuickActionsSection(),
        const SizedBox(height: 16),
        _RecentLeavesSection(leaves: data.recentLeaveRequests),
        const SizedBox(height: 16),
        _BirthdaysSection(birthdays: data.upcomingBirthdays),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Actions rapides'),
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
                icon: Icons.event_available_outlined,
                label: 'Traiter les congés',
                bg: const Color(0xFF22856A),
                onTap: () => context.go(AppRoutes.conges),
              ),
              _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Calculer la paie',
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
      color: bg.withValues(alpha: 0.10),
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
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: bg),
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
  const _RecentLeavesSection({required this.leaves});

  final List<LeaveRequest> leaves;

  static String _label(String status) => switch (status) {
        'EN_ATTENTE' => 'En attente',
        'APPROUVE' => 'Approuvé',
        'REFUSE' => 'Refusé',
        _ => status,
      };

  static String _badge(String status) => switch (status) {
        'EN_ATTENTE' => 'pending',
        'APPROUVE' => 'active',
        _ => 'rejected',
      };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _CardTitle('Demandes de congé récentes'),
              TextButton(
                onPressed: () => context.go(AppRoutes.conges),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('Voir tout',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (leaves.isEmpty) const _EmptyHint('Aucune demande de congé récente.'),
          ...leaves.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  EmployeeAvatar(name: item.employeeName, imageUrl: item.avatarUrl, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.employeeName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${fmt.format(item.startDate)} → ${fmt.format(item.endDate)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.text2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusBadge(label: _label(item.status), type: _badge(item.status)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Anniversaires à venir (30 jours) ─────────────────────────────────────────

class _BirthdaysSection extends StatelessWidget {
  const _BirthdaysSection({required this.birthdays});

  final List<Birthday> birthdays;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM', 'fr');
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Anniversaires (30 prochains jours)'),
          const SizedBox(height: 12),
          if (birthdays.isEmpty) const _EmptyHint('Aucun anniversaire dans les 30 prochains jours.'),
          ...birthdays.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  EmployeeAvatar(name: item.employeeName, imageUrl: item.avatarUrl, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.employeeName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1)),
                        Text(
                            item.daysUntilBirthday == 0
                                ? "Aujourd'hui"
                                : '${fmt.format(item.birthDate)} • dans ${item.daysUntilBirthday} j',
                            style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.card_giftcard_outlined, color: AppColors.accent, size: 16),
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
                  final createdEmail = emailCtrl.text.trim();
                  Navigator.pop(ctx);
                  final tempPassword = ref.read(adminNotifierProvider).lastTemporaryPassword;
                  if (tempPassword != null && mounted) {
                    await showTemporaryPasswordDialog(context,
                        email: createdEmail, password: tempPassword);
                  }
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

/// Nombre réel d'utilisateurs actifs par rôle.
final _roleStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/admin/roles/stats');
  return (resp.data ?? const <String, dynamic>{})
      .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
});

class _RolesSection extends ConsumerWidget {
  const _RolesSection();

  /// Rôles techniques regroupés sous chaque carte.
  static const _roleKeys = {
    'Administrateur': ['SUPER_ADMIN', 'ADMIN'],
    'RH Manager': ['HR_ADMIN', 'RH_MANAGER'],
    'Direction': ['DIRECTION'],
    'Employé': ['EMPLOYEE'],
  };

  static const _roles = [
    (
      role: 'Administrateur',
      icon: Icons.shield_outlined,
      color: AppColors.primary,
      description: 'Accès total à toutes les fonctionnalités de la plateforme.',
      permissions: ['Gestion des utilisateurs', 'Configuration système', 'Tous les modules RH', 'Rapports exécutifs', 'Données sensibles'],
      count: 0,
    ),
    (
      role: 'RH Manager',
      icon: Icons.manage_accounts_outlined,
      color: Color(0xFF22856A),
      description: 'Gestion complète des employés, congés, présences et paie.',
      permissions: ['Liste & dossiers employés', 'Validation des congés', 'Suivi des présences', 'Calcul et bulletins de paie', 'Rapports RH'],
      count: 0,
    ),
    (
      role: 'Direction',
      icon: Icons.query_stats_outlined,
      color: Color(0xFF2D7FF9),
      description: 'Lecture seule sur les indicateurs stratégiques et rapports.',
      permissions: ['Dashboard exécutif', 'Rapports et exports', 'KPI globaux', 'Masse salariale'],
      count: 0,
    ),
    (
      role: 'Employé',
      icon: Icons.badge_outlined,
      color: AppColors.text2,
      description: 'Accès à son propre espace : profil, congés et bulletins.',
      permissions: ['Profil personnel', 'Demande de congé', 'Suivi présences', 'Bulletins de paie'],
      count: 0,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_roleStatsProvider).valueOrNull ?? const <String, int>{};
    int countFor(String role) =>
        (_roleKeys[role] ?? const <String>[]).fold(0, (sum, key) => sum + (stats[key] ?? 0));
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: _roles
          .map((r) => _RoleCard(
                r: (
                  role: r.role,
                  icon: r.icon,
                  color: r.color,
                  description: r.description,
                  permissions: r.permissions,
                  count: countFor(r.role),
                ),
              ))
          .toList(),
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
        prov.applyLoadedSettings(bools);
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
              icon: Icons.timer_outlined,
              title: 'Déconnexion automatique',
              subtitle: "Ferme la session après une période d'inactivité (appliqué à la prochaine connexion).",
              value: s['AUTO_LOGOUT'] ?? true,
              onChanged: (v) => _toggle('AUTO_LOGOUT', v),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _SettingRow(
              icon: Icons.notifications_outlined,
              title: 'Notifications in-app',
              subtitle: 'Active ou suspend l’envoi des notifications (congés, paie, pointage).',
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
              icon: Icons.monitor_heart_outlined,
              iconColor: const Color(0xFF2D7FF9),
              title: 'État du serveur',
              lines: ['Vérifie en direct la disponibilité de l’API et de la base de données.'],
              action: _HealthCheckButton(),
            ),
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


