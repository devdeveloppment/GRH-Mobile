import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/core/providers/auth_provider.dart';
import 'package:grh_mobile/core/providers/conge_provider.dart';
import 'package:grh_mobile/core/providers/notification_provider.dart';
import 'package:grh_mobile/core/providers/paie_provider.dart';
import 'package:grh_mobile/core/providers/presence_provider.dart';
import 'package:grh_mobile/core/providers/profile_provider.dart';
import 'package:grh_mobile/core/providers/qr_provider.dart';
import 'package:grh_mobile/core/services/api_service.dart';
import 'package:grh_mobile/core/utils/formatters.dart';
import 'package:grh_mobile/shared/models/conge.dart';
import 'package:grh_mobile/shared/models/employe.dart';
import 'package:grh_mobile/shared/models/fiche_paie.dart';
import 'package:grh_mobile/shared/models/notification_model.dart';
import 'package:grh_mobile/shared/models/presence.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';
import 'package:grh_mobile/shared/widgets/status_badge.dart';

// ── Providers pour les sous-onglets employé ───────────────────────────────────

final _myDocumentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/employees/me/documents');
  return (resp.data?['items'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ??
      [];
});

final _myObjectifsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/employees/me/objectifs');
  return (resp.data?['items'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ??
      [];
});

final _myEvaluationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.get<Map<String, dynamic>>('/employees/me/evaluations');
  return (resp.data?['items'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ??
      [];
});

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

const _kR = 16.0;
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

BoxDecoration _card({double r = _kR, Color? color}) => BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(r),
      boxShadow: _kCardShadow,
    );

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EmployeeWorkspaceScreen extends ConsumerStatefulWidget {
  const EmployeeWorkspaceScreen({super.key});

  @override
  ConsumerState<EmployeeWorkspaceScreen> createState() =>
      _EmployeeWorkspaceScreenState();
}

class _EmployeeWorkspaceScreenState
    extends ConsumerState<EmployeeWorkspaceScreen> {
  int _tab = 0;
  FichePaie? _selectedPayslip;
  bool _showLeaveForm = false;

  static const _titles = ['Accueil', 'Présences', 'Congés', 'Paie', 'Plus'];

  String get _title {
    if (_selectedPayslip != null) return 'Bulletin de paie';
    if (_tab == 2 && _showLeaveForm) return 'Demande de congé';
    return _titles[_tab];
  }

  bool get _showBack =>
      _selectedPayslip != null || (_tab == 2 && _showLeaveForm);

  void _handleBack() {
    if (_selectedPayslip != null) {
      setState(() => _selectedPayslip = null);
    } else {
      setState(() => _showLeaveForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth         = ref.watch(authNotifierProvider);
    final conge        = ref.watch(congeNotifierProvider);
    final paie         = ref.watch(myPaieNotifierProvider);
    final presence     = ref.watch(presenceNotifierProvider);
    final notifNotif   = ref.watch(notificationNotifierProvider);
    final profileAsync = ref.watch(profileProvider);
    final user         = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _AppBar(
        title: _title,
        showBell: _tab == 0 && !_showBack,
        showBack: _showBack,
        unreadCount: notifNotif.unreadCount,
        userName: user?.fullName,
        avatarUrl: user?.avatarUrl,
        onBack: _handleBack,
        onBellTap: () => _showNotificationsSheet(context, notifNotif),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width >= 680
                ? 430
                : double.infinity,
          ),
          child: IndexedStack(
            index: _tab,
            children: [
              // 0 — Accueil
              _DashboardTab(
                auth: auth,
                profileAsync: profileAsync,
                presence: presence,
                conge: conge,
                onGoPresences: () => setState(() => _tab = 1),
                onGoConges:    () => setState(() => _tab = 2),
                onGoPaie:      () => setState(() => _tab = 3),
                onGoProfile:   () => setState(() => _tab = 4),
              ),
              // 1 — Présences
              _PresencesTab(presence: presence),
              // 2 — Congés
              _CongesTab(
                conge: conge,
                showForm: _showLeaveForm,
                onShowForm: (v) => setState(() => _showLeaveForm = v),
                ref: ref,
              ),
              // 3 — Paie
              _selectedPayslip != null
                  ? _PayslipDetail(
                      payslip: _selectedPayslip!,
                      ref: ref,
                    )
                  : _PayslipList(
                      paie: paie,
                      ref: ref,
                      onSelect: (p) => setState(() => _selectedPayslip = p),
                    ),
              // 4 — Plus
              _PlusTab(
                auth: auth,
                profileAsync: profileAsync,
                onLogout: () => ref.read(authNotifierProvider).logout(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _showBack
          ? null
          : _BottomNav(
              index: _tab,
              onChanged: (i) => setState(() {
                _tab = i;
                if (i != 3) _selectedPayslip = null;
                if (i != 2) _showLeaveForm = false;
              }),
            ),
    );
  }

  void _showNotificationsSheet(
      BuildContext context, NotificationNotifier notif) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(notifier: notif),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    required this.title,
    required this.onBellTap,
    this.showBell = false,
    this.showBack = false,
    this.unreadCount = 0,
    this.userName,
    this.avatarUrl,
    this.onBack,
  });

  final String title;
  final bool showBell;
  final bool showBack;
  final int unreadCount;
  final String? userName;
  final String? avatarUrl;
  final VoidCallback? onBack;
  final VoidCallback onBellTap;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        if (showBell)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: onBellTap,
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 24),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        if (userName != null && !showBack)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child:
                EmployeeAvatar(name: userName!, imageUrl: avatarUrl, size: 34),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined,         Icons.home_rounded,            'Accueil'),
      (Icons.fact_check_outlined,   Icons.fact_check_rounded,      'Présences'),
      (Icons.beach_access_outlined, Icons.beach_access_rounded,    'Congés'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded,    'Paie'),
      (Icons.grid_view_outlined,    Icons.grid_view_rounded,       'Plus'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final (off, on, label) = items[i];
              final sel = i == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(sel ? on : off,
                          color: sel
                              ? AppColors.accent
                              : const Color(0xFFB0B0B0),
                          size: 22),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: sel
                                ? AppColors.accent
                                : const Color(0xFFB0B0B0),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 — ACCUEIL (dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.auth,
    required this.profileAsync,
    required this.presence,
    required this.conge,
    required this.onGoPresences,
    required this.onGoConges,
    required this.onGoPaie,
    required this.onGoProfile,
  });

  final AuthNotifier auth;
  final AsyncValue<Employe> profileAsync;
  final PresenceNotifier presence;
  final CongeNotifier conge;
  final VoidCallback onGoPresences;
  final VoidCallback onGoConges;
  final VoidCallback onGoPaie;
  final VoidCallback onGoProfile;

  @override
  Widget build(BuildContext context) {
    final userName = profileAsync.valueOrNull?.fullName ?? auth.user?.fullName ?? 'Collaborateur';
    final poste    = profileAsync.valueOrNull?.poste ?? '';
    final avatarUrl = auth.user?.avatarUrl;

    final pendingCount =
        conge.demandes.where((d) => d.statut == 'EN_ATTENTE').length;

    final nextLeave = conge.demandes
        .where((d) =>
            d.statut == 'APPROUVE' &&
            d.dateDebut.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        await Future.wait([
          presence.load(),
          conge.load(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // ── Hero card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(_kR),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (poste.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                poste,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    EmployeeAvatar(
                        name: userName, imageUrl: avatarUrl, size: 52),
                  ],
                ),
                const SizedBox(height: 20),
                // KPIs 2×2
                Row(
                  children: [
                    Expanded(
                      child: _HeroKpi(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Présences',
                        value: presence.isLoading
                            ? '...'
                            : '${presence.presentCount} / 22 j',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroKpi(
                        icon: Icons.beach_access_outlined,
                        label: 'Solde congés',
                        value: conge.isLoading
                            ? '...'
                            : '${conge.soldeRestant.toStringAsFixed(0)} j',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _HeroKpi(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'En attente',
                        value: '$pendingCount demande${pendingCount > 1 ? 's' : ''}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroKpi(
                        icon: Icons.trending_up_rounded,
                        label: 'Taux présence',
                        value: presence.isLoading
                            ? '...'
                            : '${presence.tauxPresence.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Prochain congé approuvé ────────────────────────────────────
          _SectionRow(label: 'Prochain congé', onMore: onGoConges),
          const SizedBox(height: 10),
          if (nextLeave.isNotEmpty)
            _NextLeaveCard(leave: nextLeave.first)
          else
            GestureDetector(
              onTap: onGoConges,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _card(),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Faire une demande de congé',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCCCCCC)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── Dernières présences ────────────────────────────────────────
          _SectionRow(label: 'Récentes présences', onMore: onGoPresences),
          const SizedBox(height: 10),
          if (presence.isLoading && presence.presences.isEmpty)
            const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accent))
          else if (presence.presences.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _card(),
              child: const Center(
                child: Text('Aucune présence ce mois.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.text2)),
              ),
            )
          else
            ...presence.presences.take(3).map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PresenceRow(item: p),
                  ),
                ),
          const SizedBox(height: 20),

          // ── Actions rapides ────────────────────────────────────────────
          const _SectionRow(label: 'Actions rapides'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _QuickAction(
                icon: Icons.person_outline_rounded,
                label: 'Mon profil',
                color: AppColors.primary,
                onTap: onGoProfile,
              ),
              _QuickAction(
                icon: Icons.fact_check_outlined,
                label: 'Mes présences',
                color: const Color(0xFF2196F3),
                onTap: onGoPresences,
              ),
              _QuickAction(
                icon: Icons.beach_access_outlined,
                label: 'Mes congés',
                color: AppColors.accent,
                onTap: onGoConges,
              ),
              _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'Mes bulletins',
                color: AppColors.success,
                onTap: onGoPaie,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PRÉSENCES
// ─────────────────────────────────────────────────────────────────────────────

class _PresencesTab extends StatefulWidget {
  const _PresencesTab({required this.presence});

  final PresenceNotifier presence;

  @override
  State<_PresencesTab> createState() => _PresencesTabState();
}

/// Jours du lundi au vendredi du mois (jours fériés non déduits).
int _workingDays(DateTime month) {
  final days = DateTime(month.year, month.month + 1, 0).day;
  var count = 0;
  for (var d = 1; d <= days; d++) {
    final weekday = DateTime(month.year, month.month, d).weekday;
    if (weekday != DateTime.saturday && weekday != DateTime.sunday) count++;
  }
  return count;
}

class _PresencesTabState extends State<_PresencesTab> {
  DateTime? _selectedAbsenceDate;
  String _absenceMotif = '';
  Presence? _selectedAbsenceToJustify;
  String _justificationText = '';

  Future<void> _effectuerPointage(String type) async {
    final presence = widget.presence;
    
    // Coordonnées par défaut (À remplacer par geolocator si désiré)
    const double latitude = 0.0;
    const double longitude = 0.0;

    // Afficher un indicateur de chargement
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    final result = type == 'ENTREE'
        ? await presence.pointageEntree(latitude: latitude, longitude: longitude)
        : await presence.pointageSortie(latitude: latitude, longitude: longitude);

    if (!mounted) return;

    if (result != null && result['statut'] == 'OK') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'ENTREE'
                ? '✓ Pointage entrée enregistré à ${_formatHeure(result['heure'])}'
                : '✓ Pointage sortie enregistré à ${_formatHeure(result['heure'])}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du pointage: ${presence.pointerError ?? 'Erreur inconnue'}',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showReportAbsenceDialog() async {
    _selectedAbsenceDate = null;
    _absenceMotif = '';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Signaler une absence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedAbsenceDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Text(
                        _selectedAbsenceDate == null
                            ? 'Choisir une date'
                            : _selectedAbsenceDate.toString().split(' ')[0],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Motif field
              TextField(
                onChanged: (v) => _absenceMotif = v,
                decoration: InputDecoration(
                  hintText: 'Motif de l\'absence',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _selectedAbsenceDate == null || _absenceMotif.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    final result = await widget.presence.reportAbsence(
                      date: _selectedAbsenceDate!,
                      motif: _absenceMotif,
                    );

                    if (!mounted) return;

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✓ Absence signalée avec succès'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur: ${widget.presence.absenceError ?? 'Erreur inconnue'}',
                          ),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJustifyAbsenceDialog() async {
    final presence = widget.presence;
    
    // Charger les absences en attente
    await presence.loadAbsencesEnAttente();

    if (!mounted) return;

    if (presence.absencesEnAttente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune absence en attente de justification'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    _selectedAbsenceToJustify = null;
    _justificationText = '';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Justifier une absence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Liste des absences
              DropdownButtonFormField<Presence>(
                value: _selectedAbsenceToJustify,
                items: presence.absencesEnAttente
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.date.toString().split(' ')[0]} - ${a.statut}'),
                      ),
                    )
                    .toList(),
                onChanged: (a) => setState(() => _selectedAbsenceToJustify = a),
                decoration: InputDecoration(
                  labelText: 'Choisir une absence',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Justification field
              TextField(
                onChanged: (v) => _justificationText = v,
                decoration: InputDecoration(
                  hintText: 'Votre justification',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 3,
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _selectedAbsenceToJustify == null || _justificationText.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    final result = await presence.justifyAbsence(
                      presenceId: _selectedAbsenceToJustify!.id,
                      justification: _justificationText,
                    );

                    if (!mounted) return;

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✓ Absence justifiée avec succès'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur: ${presence.absenceError ?? 'Erreur inconnue'}',
                          ),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('Justifier'),
          ),
        ],
      ),
    );
  }

  String _formatHeure(dynamic heure) {
    if (heure == null) return '--:--';
    try {
      final dt = DateTime.parse(heure.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final presence = widget.presence;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => presence.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // ── QR Code de pointage ───────────────────────────────────────
          const _QrPointageCard(),
          const SizedBox(height: 16),

          // ── Actions de pointage et d'absence ─────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Pointage du jour',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: presence.isPointerLoading ? null : () => _effectuerPointage('ENTREE'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Arrivée'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: presence.isPointerLoading ? null : () => _effectuerPointage('SORTIE'),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Départ'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showReportAbsenceDialog,
                        icon: const Icon(Icons.event_busy_outlined, size: 18),
                        label: const Text('Signaler une absence'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showJustifyAbsenceDialog,
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: const Text('Justifier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Month navigator ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final m = presence.currentMonth;
                  presence.changeMonth(
                      DateTime(m.year, m.month - 1));
                },
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.text1, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                AppFormatters.monthYear(presence.currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
                ),
              ),
              IconButton(
                onPressed: () {
                  final m = presence.currentMonth;
                  presence.changeMonth(
                      DateTime(m.year, m.month + 1));
                },
                icon: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.text1, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stats chips ───────────────────────────────────────────────
          if (presence.isLoading && presence.presences.isEmpty)
            const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accent))
          else ...[
            Row(
              children: [
                _StatChip(label: 'Ouvrables', value: '${_workingDays(presence.currentMonth)}'),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'Présents',
                    value: '${presence.presentCount}',
                    color: AppColors.success),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'Absences',
                    value: '${presence.absentCount}',
                    color: AppColors.error),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'Taux',
                    value:
                        '${presence.tauxPresence.toStringAsFixed(0)}%',
                    color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 20),

            // ── Calendar ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: _MonthCalendar(
                month: presence.currentMonth,
                presentDays: presence.presentDays,
                absentDays: presence.absentDays,
                retardDays: presence.retardDays,
              ),
            ),
            const SizedBox(height: 16),

            // ── Legend ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: AppColors.success, label: 'Présent'),
                SizedBox(width: 20),
                _Legend(color: Color(0xFFFF9800), label: 'Retard'),
                SizedBox(width: 20),
                _Legend(color: AppColors.error, label: 'Absent'),
                SizedBox(width: 20),
                _Legend(color: Color(0xFFDDDDDD), label: 'Week-end'),
              ],
            ),
            const SizedBox(height: 20),

            // ── Recent list ───────────────────────────────────────────
            if (presence.presences.isNotEmpty) ...[
              const Text(
                'Détail des pointages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
                ),
              ),
              const SizedBox(height: 10),
              ...presence.presences.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PresenceRow(item: p),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — CONGÉS
// ─────────────────────────────────────────────────────────────────────────────

class _CongesTab extends StatefulWidget {
  const _CongesTab({
    required this.conge,
    required this.showForm,
    required this.onShowForm,
    required this.ref,
  });

  final CongeNotifier conge;
  final bool showForm;
  final ValueChanged<bool> onShowForm;
  final WidgetRef ref;

  @override
  State<_CongesTab> createState() => _CongesTabState();
}

class _CongesTabState extends State<_CongesTab> {
  int _sub = 0;
  final _motifCtrl = TextEditingController();
  String _type = 'Annuel';
  DateTimeRange? _range;

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.showForm ? _buildForm() : _buildList();
  }

  Widget _buildList() {
    final approved = widget.conge.demandes
        .where((d) => d.statut == 'APPROUVE')
        .toList();
    final history = widget.conge.demandes
        .where((d) => d.statut != 'APPROUVE')
        .toList();
    final shown = _sub == 0 ? approved : history;

    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _TabLabel(
                  label: 'Mes congés',
                  selected: _sub == 0,
                  onTap: () => setState(() => _sub = 0)),
              _TabLabel(
                  label: 'Historique',
                  selected: _sub == 1,
                  onTap: () => setState(() => _sub = 1)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => widget.conge.load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: widget.conge.isLoading && shown.isEmpty
                  ? [
                      const SizedBox(height: 40),
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                    ]
                  : shown.isEmpty
                      ? [
                          const SizedBox(height: 40),
                          const Center(
                            child: Text('Aucun congé enregistré.',
                                style: TextStyle(
                                    color: AppColors.text2,
                                    fontSize: 13)),
                          ),
                        ]
                      : shown
                          .map((c) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _LeaveCard(item: c),
                              ))
                          .toList(),
            ),
          ),
        ),
        // Solde + CTA
        Container(
          padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                top: BorderSide(
                    color: Color(0xFFEEEEEE), width: 1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Solde restant',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.text2)),
                  Text(
                    '${widget.conge.soldeRestant.toStringAsFixed(0)} jours',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => widget.onShowForm(true),
                  child: const Text('Faire une demande de congé',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final days =
        _range == null ? 0 : _range!.duration.inDays + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // Type
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FLabel(text: 'Type de congé'),
              const SizedBox(height: 8),
              _Dropdown(
                value: _type,
                // Valeurs alignées sur TypeConge côté serveur
                items: const [
                  'Annuel',
                  'Maladie',
                  'Maternite',
                  'Sans Solde',
                ],
                labels: const [
                  'Congé annuel',
                  'Congé maladie',
                  'Congé maternité',
                  'Sans solde',
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Dates
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateRow(
                label: 'Date de début',
                value: _range == null
                    ? null
                    : AppFormatters.shortDate(_range!.start),
                onTap: _pickRange,
              ),
              const Divider(
                  height: 20,
                  color: Color(0xFFF0F0F0)),
              _DateRow(
                label: 'Date de fin',
                value: _range == null
                    ? null
                    : AppFormatters.shortDate(_range!.end),
                onTap: _pickRange,
              ),
              if (days > 0) ...[
                const Divider(
                    height: 20,
                    color: Color(0xFFF0F0F0)),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nombre de jours',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text2)),
                    Text('$days jours',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        )),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Motif
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FLabel(text: 'Motif (optionnel)'),
              const SizedBox(height: 8),
              TextField(
                controller: _motifCtrl,
                minLines: 3,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Écrire le motif',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed:
                widget.conge.isLoading ? null : _submit,
            child: widget.conge.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Soumettre la demande',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate:
          DateTime.now().subtract(const Duration(days: 30)),
      lastDate:
          DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
      locale: const Locale('fr', 'TG'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _submit() async {
    if (_range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez choisir une période.')),
      );
      return;
    }
    final ok = await widget.ref.read(congeNotifierProvider).submitRequest(
          typeConge: _type,
          dateDebut: _range!.start,
          dateFin: _range!.end,
          motif: _motifCtrl.text.trim().isEmpty
              ? null
              : _motifCtrl.text.trim(),
        );
    if (ok && mounted) {
      _motifCtrl.clear();
      setState(() => _range = null);
      widget.onShowForm(false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — PAIE
// ─────────────────────────────────────────────────────────────────────────────

class _PayslipList extends StatelessWidget {
  const _PayslipList({
    required this.paie,
    required this.ref,
    required this.onSelect,
  });

  final PaieNotifier paie;
  final WidgetRef ref;
  final ValueChanged<FichePaie> onSelect;

  @override
  Widget build(BuildContext context) {
    if (paie.isLoading && paie.bulletins.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (paie.bulletins.isEmpty) {
      return const Center(
        child: Text('Aucun bulletin disponible.',
            style: TextStyle(color: AppColors.text2, fontSize: 13)),
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref
          .read(myPaieNotifierProvider)
          .loadForPeriod(DateTime.now()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        itemCount: paie.bulletins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final p = paie.bulletins[i];
          return GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.periode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text1,
                            )),
                        const SizedBox(height: 3),
                        Text(AppFormatters.currency(p.salaireNet),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.text2)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _download(context, ref, p),
                    icon: const Icon(Icons.download_outlined,
                        color: AppColors.primary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _download(
      BuildContext ctx, WidgetRef r, FichePaie p) async {
    final path = await r.read(myPaieNotifierProvider).downloadPayslip(
          p.id,
          p.nomEmploye ?? 'employe',
        );
    if (path != null && !kIsWeb) await OpenFilex.open(path);
    if (ctx.mounted && path == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Téléchargement impossible.')),
      );
    }
  }
}

class _PayslipDetail extends StatelessWidget {
  const _PayslipDetail({required this.payslip, required this.ref});

  final FichePaie payslip;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // Salary hero
        Container(
          padding: const EdgeInsets.symmetric(
              vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(_kR),
          ),
          child: Column(
            children: [
              Text(payslip.periode,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              const Text('Salaire net',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                AppFormatters.currency(payslip.salaireNet),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _card(),
          child: Column(
            children: [
              _PayRow('Salaire de base', payslip.salaireBrut, false),
              _PayRow('Primes', payslip.indemnites, false),
              _PayRow('Indemnités', payslip.indemnites, false),
              _PayRow('CNSS (4%)', payslip.cotisations, true),
              _PayRow('Impôts', payslip.impots, true),
              const Divider(
                  height: 24, color: Color(0xFFF0F0F0)),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Salaire brut',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1)),
                  Text(AppFormatters.currency(payslip.salaireBrut),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _download(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Télécharger le bulletin',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                  color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _download(context),
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
            label: const Text('Voir le bulletin détaillé',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext ctx) async {
    final path = await ref.read(myPaieNotifierProvider).downloadPayslip(
          payslip.id,
          payslip.nomEmploye ?? 'employe',
        );
    if (path != null && !kIsWeb) {
      await OpenFilex.open(path);
    } else if (ctx.mounted && path == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('Téléchargement impossible.')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — PLUS
// ─────────────────────────────────────────────────────────────────────────────

class _PlusTab extends StatelessWidget {
  const _PlusTab({
    required this.auth,
    required this.profileAsync,
    required this.onLogout,
  });

  final AuthNotifier auth;
  final AsyncValue<Employe> profileAsync;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final user  = auth.user;
    final emp   = profileAsync.valueOrNull;
    final name  = emp?.fullName ?? user?.fullName ?? 'Utilisateur';
    final poste = emp?.poste ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // Profile summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(),
          child: Row(
            children: [
              EmployeeAvatar(
                  name: name, imageUrl: user?.avatarUrl, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        )),
                    if (poste.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(poste,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text2)),
                    ],
                    if (emp != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          emp.statut,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Menu
        Container(
          decoration: _card(),
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Mon profil',
                onTap: () => _showProfileSheet(context, emp),
              ),
              _MenuItem(
                icon: Icons.folder_outlined,
                label: 'Mes documents',
                onTap: () => _showSheet(context, const _DocumentsSheet()),
              ),
              _MenuItem(
                icon: Icons.flag_outlined,
                label: 'Mes objectifs',
                onTap: () => _showSheet(context, const _ObjectifsSheet()),
              ),
              _MenuItem(
                icon: Icons.star_border_rounded,
                label: 'Mes évaluations',
                onTap: () => _showSheet(context, const _EvaluationsSheet()),
              ),
              _MenuItem(
                icon: Icons.people_outline_rounded,
                label: 'Annuaire des employés',
                onTap: () => _showSheet(context, const _AnnuaireSheet()),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Paramètres',
                onTap: () => _showSheet(context, const _ParametresSheet()),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Aide et support',
                onTap: () => _showSheet(context, const _AideSheet()),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: _card(),
          child: _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Déconnexion',
            color: AppColors.error,
            onTap: onLogout,
            isLast: true,
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext ctx, Widget sheet) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  void _showProfileSheet(BuildContext context, Employe? emp) {
    if (emp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement du profil en cours, veuillez patienter.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(emp: emp),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Notifications
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.notifier});

  final NotificationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        )),
                  ),
                  if (notifier.unreadCount > 0)
                    TextButton(
                      onPressed: notifier.markAllAsRead,
                      child: const Text('Tout lire',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Expanded(
              child: notifier.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : notifier.notifications.isEmpty
                      ? const Center(
                          child: Text('Aucune notification.',
                              style: TextStyle(
                                  color: AppColors.text2,
                                  fontSize: 13)))
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 20),
                          itemCount: notifier.notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(
                                  height: 1,
                                  color: Color(0xFFF5F5F5)),
                          itemBuilder: (ctx, i) {
                            final n = notifier.notifications[i];
                            return _NotifTile(
                              notif: n,
                              onTap: () => notifier.markAsRead(n.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});

  final AppNotification notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notif.type) {
      'conge'     => (Icons.beach_access_outlined, AppColors.accent),
      'paie'      => (Icons.receipt_long_outlined, AppColors.primary),
      'event'     => (Icons.event_outlined,        const Color(0xFF9C27B0)),
      'document'  => (Icons.folder_outlined,       const Color(0xFF2196F3)),
      'formation' => (Icons.school_outlined,       AppColors.success),
      _           => (Icons.info_outline_rounded,  AppColors.text2),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: notif.read ? Colors.transparent : AppColors.accent.withValues(alpha: 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notif.titre != null)
                    Text(notif.titre!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text1,
                        )),
                  const SizedBox(height: 2),
                  Text(notif.message,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.text2)),
                  const SizedBox(height: 4),
                  Text(AppFormatters.relativeTime(notif.date),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.text2)),
                ],
              ),
            ),
            if (!notif.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Profil
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.emp});

  final Employe emp;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
                child: EmployeeAvatar(
                    name: emp.fullName, size: 72)),
            const SizedBox(height: 12),
            Center(
              child: Text(emp.fullName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1)),
            ),
            Center(
              child: Text(emp.poste,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.text2)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emp.statut,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    )),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            const Text('Informations personnelles',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1)),
            const SizedBox(height: 12),
            _ProfileRow(Icons.email_outlined,    'Email',     emp.email),
            if (emp.telephone != null)
              _ProfileRow(Icons.phone_outlined, 'Téléphone', emp.telephone!),
            if (emp.adresse != null)
              _ProfileRow(Icons.location_on_outlined, 'Adresse', emp.adresse!),
            if (emp.dateNaissance != null)
              _ProfileRow(Icons.cake_outlined, 'Naissance',
                  AppFormatters.shortDate(emp.dateNaissance)),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            const Text('Informations professionnelles',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1)),
            const SizedBox(height: 12),
            _ProfileRow(Icons.badge_outlined,  'Matricule', emp.matricule),
            _ProfileRow(Icons.business_outlined, 'Service', emp.service),
            _ProfileRow(Icons.work_outline_rounded, 'Contrat', emp.typeContrat),
            if (emp.dateEmbauche != null)
              _ProfileRow(Icons.calendar_today_outlined, 'Embauche',
                  AppFormatters.shortDate(emp.dateEmbauche)),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.text2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.text2)),
          ),
          Expanded(
            flex: 2,
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text1,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE MICRO-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    )),
                Text(label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.label, this.onMore});

  final String label;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1)),
        ),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: const Text('Voir tout',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                )),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text1,
                )),
          ],
        ),
      ),
    );
  }
}

class _NextLeaveCard extends StatelessWidget {
  const _NextLeaveCard({required this.leave});

  final Conge leave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.beach_access_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leave.typeConge,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1,
                    )),
                const SizedBox(height: 3),
                Text(
                  'Du ${AppFormatters.shortDate(leave.dateDebut)} au ${AppFormatters.shortDate(leave.dateFin)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.text2),
                ),
                const SizedBox(height: 2),
                Text('${leave.nombreJours} jours',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text2)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Approuvé',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                )),
          ),
        ],
      ),
    );
  }
}

class _PresenceRow extends StatelessWidget {
  const _PresenceRow({required this.item});

  final Presence item;

  @override
  Widget build(BuildContext context) {
    final (label, type) = switch (item.statut) {
      'PRESENT' => ('Présent', 'active'),
      'RETARD'  => ('Retard',  'pending'),
      _         => ('Absent',  'rejected'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card(r: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fact_check_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormatters.longDate(item.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text1,
                    )),
                const SizedBox(height: 2),
                Text(
                  '${item.heureArrivee != null ? AppFormatters.time(item.heureArrivee) : '--:--'} → ${item.heureDepart != null ? AppFormatters.time(item.heureDepart) : '--:--'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.text2),
                ),
              ],
            ),
          ),
          StatusBadge(label: label, type: type),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 4),
        decoration: _card(r: 12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color ?? AppColors.text1,
                )),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.text2)),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.presentDays,
    required this.absentDays,
    required this.retardDays,
  });

  final DateTime month;
  final Set<String> presentDays;
  final Set<String> absentDays;
  final Set<String> retardDays;

  @override
  Widget build(BuildContext context) {
    const headers = [
      'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
    ];
    final first  = DateTime(month.year, month.month, 1);
    final offset = (first.weekday - 1) % 7;
    final total  = DateTime(month.year, month.month + 1, 0).day;

    return Column(
      children: [
        Row(
          children: headers
              .map((h) => Expanded(
                    child: Center(
                      child: Text(h,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text2,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
          ),
          itemCount: offset + total,
          itemBuilder: (ctx, i) {
            if (i < offset) return const SizedBox.shrink();
            final day  = i - offset + 1;
            final date = DateTime(month.year, month.month, day);
            final key  = date.toIso8601String().substring(0, 10);
            final weekend  = date.weekday >= 6;
            final isPresent = presentDays.contains(key);
            final isAbsent  = absentDays.contains(key);
            final isRetard  = retardDays.contains(key);
            final isToday = _same(date, DateTime.now());

            Color? bg;
            Color txt = AppColors.text1;

            if (isPresent) { bg = AppColors.success; txt = Colors.white; }
            else if (isAbsent) { bg = AppColors.error; txt = Colors.white; }
            else if (isRetard) { bg = const Color(0xFFFF9800); txt = Colors.white; }
            else if (isToday)  { bg = AppColors.primary; txt = Colors.white; }
            else if (weekend)  { bg = const Color(0xFFEEEEEE); txt = const Color(0xFFAAAAAA); }

            return Container(
              decoration: BoxDecoration(
                  color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: txt,
                  )),
            );
          },
        ),
      ],
    );
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.text2)),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? AppColors.accent
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? AppColors.accent
                    : AppColors.text2,
              )),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.item});

  final Conge item;

  @override
  Widget build(BuildContext context) {
    final (lbl, type) = switch (item.statut) {
      'APPROUVE' => ('Approuvé', 'active'),
      'REFUSE'   => ('Rejeté',  'rejected'),
      _          => ('En attente', 'pending'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.typeConge,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1,
                    )),
              ),
              StatusBadge(label: lbl, type: type),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Du ${AppFormatters.shortDate(item.dateDebut)} au ${AppFormatters.shortDate(item.dateFin)}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.text2),
          ),
          const SizedBox(height: 4),
          Text('${item.nombreJours} jours',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2)),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow(this.label, this.amount, this.deduction);

  final String label;
  final double amount;
  final bool deduction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.text2)),
          Text(
            '${deduction ? '-' : ''}${AppFormatters.currency(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: deduction ? AppColors.error : AppColors.text1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text1;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(
                  bottom: Radius.circular(_kR))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: c, size: 20),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c,
                        ))),
                Icon(Icons.chevron_right_rounded,
                    color: color != null
                        ? color!.withValues(alpha: 0.4)
                        : const Color(0xFFCCCCCC),
                    size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              indent: 50,
              endIndent: 16,
              color: Color(0xFFF5F5F5)),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: child,
      );
}

class _FLabel extends StatelessWidget {
  const _FLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text2));
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.text1,
              fontWeight: FontWeight.w500),
          items: List.generate(
            items.length,
            (i) => DropdownMenuItem(
                value: items[i], child: Text(labels[i])),
          ),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.onTap,
    this.value,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.text2)),
                const SizedBox(height: 4),
                Text(
                  value ?? 'Sélectionner',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: value != null
                        ? AppColors.text1
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_today_outlined,
              color: AppColors.text2, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — handle + title helper
// ─────────────────────────────────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
    this.initialSize = 0.75,
  });

  final String title;
  final Widget child;
  final double initialSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        )),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Mes Documents
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentsSheet extends ConsumerWidget {
  const _DocumentsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myDocumentsProvider);
    return _SheetScaffold(
      title: 'Mes documents',
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Text('Erreur de chargement',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (docs) => docs.isEmpty
            ? const Center(
                child: Text('Aucun document disponible.',
                    style: TextStyle(color: AppColors.text2, fontSize: 13)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF5F5F5)),
                itemBuilder: (ctx, i) => _DocumentTile(doc: docs[i]),
              ),
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final Map<String, dynamic> doc;

  static IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'image': return Icons.image_outlined;
      case 'xlsx':
      case 'xls': return Icons.table_chart_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = doc['nom'] as String? ?? 'Document';
    final type = doc['type'] as String? ?? '';
    final tailleKo = doc['tailleKo'] as int? ?? 0;
    final url = doc['url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(type), color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1)),
                const SizedBox(height: 2),
                Text('${tailleKo} Ko · $type',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.text2)),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Télécharger',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(apiServiceProvider).downloadFile(url, nom);
                  messenger.showSnackBar(const SnackBar(content: Text('Document téléchargé.')));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(ApiService.messageOf(e, 'Téléchargement impossible.'))));
                }
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Mes Objectifs
// ─────────────────────────────────────────────────────────────────────────────

class _ObjectifsSheet extends ConsumerWidget {
  const _ObjectifsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myObjectifsProvider);
    return _SheetScaffold(
      title: 'Mes objectifs',
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (_, __) => const Center(
          child: Text('Erreur de chargement',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        color: AppColors.text2.withOpacity(0.4), size: 48),
                    const SizedBox(height: 12),
                    const Text('Aucun objectif défini.',
                        style: TextStyle(color: AppColors.text2, fontSize: 13)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF5F5F5)),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final titre = item['titre'] as String? ?? 'Objectif';
                  final statut = item['statut'] as String? ?? 'EN_COURS';
                  final desc = item['description'] as String?;
                  final (label, color) = switch (statut) {
                    'ATTEINT' => ('Atteint', AppColors.success),
                    'NON_ATTEINT' => ('Non atteint', AppColors.error),
                    _ => ('En cours', AppColors.accent),
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(titre,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text1)),
                              if (desc != null && desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(desc,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.text2)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Mes Évaluations
// ─────────────────────────────────────────────────────────────────────────────

class _EvaluationsSheet extends ConsumerWidget {
  const _EvaluationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myEvaluationsProvider);
    return _SheetScaffold(
      title: 'Mes évaluations',
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (_, __) => const Center(
          child: Text('Erreur de chargement',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_border_rounded,
                        color: AppColors.text2.withOpacity(0.4), size: 48),
                    const SizedBox(height: 12),
                    const Text('Aucune évaluation enregistrée.',
                        style: TextStyle(color: AppColors.text2, fontSize: 13)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF5F5F5)),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final periode = item['periode'] as String? ?? '';
                  final note = item['note'];
                  final commentaire = item['commentaire'] as String?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(periode,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text1)),
                            ),
                            if (note != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('$note / 10',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ),
                          ],
                        ),
                        if (commentaire != null && commentaire.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(commentaire,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.text2)),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Annuaire des employés
// ─────────────────────────────────────────────────────────────────────────────

class _AnnuaireSheet extends ConsumerStatefulWidget {
  const _AnnuaireSheet();

  @override
  ConsumerState<_AnnuaireSheet> createState() => _AnnuaireSheetState();
}

final _annuaireProvider = FutureProvider.autoDispose<List<Employe>>((ref) async {
  final resp = await ref.read(apiServiceProvider).get<Map<String, dynamic>>('/employees/annuaire');
  final raw = resp.data?['items'] as List? ?? const [];
  return raw.whereType<Map<String, dynamic>>().map(Employe.fromJson).toList();
});

class _AnnuaireSheetState extends ConsumerState<_AnnuaireSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(_annuaireProvider).valueOrNull ?? const <Employe>[];
    final employees = all.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.fullName.toLowerCase().contains(q) ||
          e.poste.toLowerCase().contains(q) ||
          e.service.toLowerCase().contains(q);
    }).toList();

    return _SheetScaffold(
      title: 'Annuaire',
      initialSize: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un collègue…',
                hintStyle:
                    const TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.text2, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.text2, size: 18),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: ref.watch(_annuaireProvider).isLoading && employees.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : employees.isEmpty
                    ? const Center(
                        child: Text('Aucun résultat.',
                            style: TextStyle(
                                color: AppColors.text2, fontSize: 13)))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFFF5F5F5)),
                        itemBuilder: (ctx, i) =>
                            _AnnuaireTile(emp: employees[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AnnuaireTile extends StatelessWidget {
  const _AnnuaireTile({required this.emp});
  final Employe emp;

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          EmployeeAvatar(name: emp.fullName, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.fullName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text1)),
                const SizedBox(height: 2),
                Text('${emp.poste} · ${emp.service}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.text2)),
              ],
            ),
          ),
          if (emp.telephone != null && emp.telephone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone_outlined,
                  color: AppColors.primary, size: 20),
              tooltip: 'Appeler',
              onPressed: () => _call(emp.telephone!),
            ),
          IconButton(
            icon: const Icon(Icons.email_outlined,
                color: AppColors.accent, size: 20),
            tooltip: 'Envoyer un email',
            onPressed: () => _email(emp.email),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Paramètres
// ─────────────────────────────────────────────────────────────────────────────

class _ParametresSheet extends ConsumerStatefulWidget {
  const _ParametresSheet();

  @override
  ConsumerState<_ParametresSheet> createState() => _ParametresSheetState();
}

class _ParametresSheetState extends ConsumerState<_ParametresSheet> {
  bool _notificationsEnabled = true;
  bool _loading = true;

  static const _kNotifKey = 'pref_notif_enabled';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_kNotifKey) ?? true;
      _loading = false;
    });
  }

  Future<void> _setNotif(bool v) async {
    setState(() => _notificationsEnabled = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, v);
  }

  Future<void> _showChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Changer le mot de passe',
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
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirmer',
                    border: OutlineInputBorder()),
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
                if (newCtrl.text != confirmCtrl.text) {
                  setS(() => error = 'Les mots de passe ne correspondent pas.');
                  return;
                }
                if (newCtrl.text.length < 8) {
                  setS(() => error =
                      'Le mot de passe doit comporter au moins 8 caractères.');
                  return;
                }
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.put<Map<String, dynamic>>(
                    '/profile/password',
                    data: {
                      'currentPassword': currentCtrl.text,
                      'newPassword': newCtrl.text,
                    },
                  );
                  await ref.read(authNotifierProvider).markPasswordChanged();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Mot de passe modifié avec succès.')),
                    );
                  }
                } catch (e) {
                  setS(() => error = ApiService.messageOf(
                      e, 'Mot de passe actuel incorrect ou erreur serveur.'));
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Paramètres',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text('Notifications',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                          letterSpacing: 0.5)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: SwitchListTile(
                    title: const Text('Activer les notifications',
                        style: TextStyle(fontSize: 14, color: AppColors.text1)),
                    subtitle: const Text('Alertes congés, paie et présences',
                        style: TextStyle(fontSize: 12, color: AppColors.text2)),
                    value: _notificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: _setNotif,
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('Sécurité',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                          letterSpacing: 0.5)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: AppColors.text2, size: 20),
                    title: const Text('Changer le mot de passe',
                        style: TextStyle(fontSize: 14, color: AppColors.text1)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCCCCCC), size: 20),
                    onTap: _showChangePassword,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Aide et Support
// ─────────────────────────────────────────────────────────────────────────────

class _AideSheet extends StatelessWidget {
  const _AideSheet();

  static const _faq = [
    (
      q: 'Comment soumettre une demande de congé ?',
      a: 'Rendez-vous dans l\'onglet "Congés", appuyez sur "Nouvelle demande" et remplissez le formulaire. Votre manager sera notifié automatiquement.',
    ),
    (
      q: 'Comment consulter mon bulletin de salaire ?',
      a: 'Dans l\'onglet "Paie", sélectionnez la période souhaitée puis appuyez sur "Voir le bulletin détaillé" pour télécharger le PDF.',
    ),
    (
      q: 'Que faire en cas d\'oubli de pointage ?',
      a: 'Contactez votre responsable RH ou signalez l\'anomalie via le bouton de support ci-dessous. Une correction manuelle sera effectuée.',
    ),
    (
      q: 'Comment modifier mes informations personnelles ?',
      a: 'Les modifications doivent être effectuées par votre responsable RH. Contactez le support pour toute demande de mise à jour.',
    ),
    (
      q: 'Mon solde de congés est incorrect, que faire ?',
      a: 'Vérifiez d\'abord l\'historique de vos congés dans l\'onglet correspondant. Si une erreur persiste, contactez votre responsable RH.',
    ),
  ];

  Future<void> _contactSupport(BuildContext ctx) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@grhmobile.tg',
      queryParameters: {'subject': 'Demande d\'assistance GRH-Mobile'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content: Text(
                  'Contactez le support : support@grhmobile.tg')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Aide et support',
      initialSize: 0.85,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Questions fréquentes',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2,
                    letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              children: _faq
                  .map((entry) => ExpansionTile(
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 14),
                        title: Text(entry.q,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text1)),
                        children: [
                          Text(entry.a,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.text2,
                                  height: 1.5)),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _contactSupport(context),
              icon: const Icon(Icons.support_agent_outlined, size: 20),
              label: const Text('Contacter le support',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// Shared page header (used by other screens via import)
class GrhPageHeader extends StatelessWidget {
  const GrhPageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text1)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.text2)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET QR POINTAGE — affiché à la place des boutons Entrée/Sortie
// ─────────────────────────────────────────────────────────────────────────────

class _QrPointageCard extends ConsumerWidget {
  const _QrPointageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qr = ref.watch(qrNotifierProvider);

    if (qr.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final code = qr.qrCode;
    if (code == null) {
      return OutlinedButton.icon(
        onPressed: () => ref.read(qrNotifierProvider).load(),
        icon: const Icon(Icons.qr_code_rounded),
        label: const Text('Charger mon QR Code'),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Mon QR Code de présence',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Présentez ce code à l\'administrateur pour pointer',
              style: TextStyle(fontSize: 12, color: AppColors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showFullscreen(context, code.qrData),
              child: QrImageView(
                data: code.qrData,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _showFullscreen(context, code.qrData),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Agrandir'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: qr.isRegenerating
                      ? null
                      : () => ref.read(qrNotifierProvider).regenerate(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                      qr.isRegenerating ? 'Régénération...' : 'Régénérer'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.text2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String data) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('QR Code',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 300,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
