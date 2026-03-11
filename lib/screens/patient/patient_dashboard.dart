import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';
import '../../screens/auth/login_screen.dart';
import '../doctor/patient_medical_history_screen.dart';
import 'prescription_detail_screen.dart';
import 'add_prescription_screen.dart';
import 'doctor_access_requests_view.dart';
import 'ai_summary_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

enum _RecordsFilter { all, prescriptions, labReports }

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedNavIndex = 0;
  _RecordsFilter _recordsFilter = _RecordsFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrescriptions();
    });
  }

  void _loadPrescriptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);
    prescriptionProvider.fetchPrescriptions(
      authProvider.currentUser!.id,
      'patient',
    );
  }

  /// Mask Aadhar as XXXX-XXXX-5678 (last 4 visible)
  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.length < 4) return 'XXXX-XXXX-XXXX';
    final digits = aadhar.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) return 'XXXX-XXXX-XXXX';
    return 'XXXX-XXXX-${digits.substring(8)}';
  }

  int _recentVisitsThisMonth(List prescriptions) {
    final now = DateTime.now();
    return prescriptions.where((p) {
      final t = p.createdAt;
      return t.year == now.year && t.month == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final prescriptionProvider = Provider.of<PrescriptionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prescriptions = prescriptionProvider.prescriptions;
    final recentCount = _recentVisitsThisMonth(prescriptions);

    return Scaffold(
      backgroundColor: isDark ? Constants.backgroundDark : Constants.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, authProvider),
            Expanded(
              child: _selectedNavIndex == 0
                  ? _buildHomeContent(
                      context,
                      authProvider,
                      prescriptionProvider,
                      prescriptions,
                      recentCount,
                      isDark,
                    )
                  : _selectedNavIndex == 1
                      ? _buildRecordsView(context, prescriptionProvider, isDark)
                      : _selectedNavIndex == 2
                          ? const DoctorAccessRequestsView()
                          : _buildProfileView(context, authProvider, isDark),
            ),
            _buildBottomNav(isDark),
          ],
        ),
      ),
      floatingActionButton: _selectedNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AISummaryScreen(
                      patient: authProvider.currentUser!,
                      records: prescriptionProvider.prescriptions,
                    ),
                  ),
                );
              },
              backgroundColor: Constants.primaryColor,
              icon: const Icon(Icons.auto_awesome, color: Constants.backgroundDark),
              label: Text(
                'AI Health Summary',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Constants.backgroundDark,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Constants.backgroundDark : Constants.backgroundLight)
            .withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Constants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Constants.primaryColor.withOpacity(0.3)),
            ),
            child: const Icon(Icons.health_and_safety, color: Constants.primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'AyuNetra',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          IconButton(
            onPressed: () {
              _showSettingsOrLogout(context, authProvider);
            },
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsOrLogout(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    AuthProvider authProvider,
    PrescriptionProvider prescriptionProvider,
    List prescriptions,
    int recentCount,
    bool isDark,
  ) {
    final user = authProvider.currentUser!;
    return RefreshIndicator(
      onRefresh: () async => _loadPrescriptions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildProfileSection(user, isDark),
            const SizedBox(height: 8),
            _buildStatsGrid(prescriptions.length, recentCount, isDark),
            const SizedBox(height: 24),
            _buildUploadButton(context),
            const SizedBox(height: 24),
            _buildRecentActivityHeader(context),
            const SizedBox(height: 12),
            prescriptionProvider.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : prescriptions.isEmpty
                    ? _buildEmptyActivity(isDark)
                    : _buildRecentActivityList(context, prescriptions, isDark),
            const SizedBox(height: 24),
            _buildSecurityBadge(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Constants.primaryColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  color: isDark ? Constants.cardDark : Colors.white,
                ),
                child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImageUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Constants.primaryColor.withOpacity(0.8),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Constants.backgroundDark : Constants.backgroundLight,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.verified, size: 14, color: Constants.backgroundDark),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 16,
                      color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _maskAadhar(user.aadharNumber),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int totalRecords, int recentVisits, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.folder_open,
              label: 'Total Records',
              value: '$totalRecords',
              badge: recentVisits > 0 ? '+$recentVisits new' : null,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.calendar_today,
              label: 'Recent Visits',
              value: '$recentVisits',
              subtitle: 'This month',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    String? subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Constants.primaryColor, size: 24),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Constants.primaryColor,
                    ),
                  ),
                )
              else if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Constants.textMutedLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Constants.primaryColor,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Constants.primaryColor.withOpacity(0.3),
        elevation: 8,
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => const AddPrescriptionScreen(),
                  ),
                )
                .then((_) => _loadPrescriptions());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Constants.backgroundDark.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    size: 32,
                    color: Constants.backgroundDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload New Record',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Constants.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan prescriptions or lab reports',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.backgroundDark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatientMedicalHistoryScreen(
                        patientId: authProvider.currentUser!.id,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Medical History',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedNavIndex = 1),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 56,
            color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No records yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(
    BuildContext context,
    List prescriptions,
    bool isDark,
  ) {
    final list = prescriptions.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(list.length, (index) {
          final p = list[index];
          return _activityTile(context, p, isDark, Icons.medication, Colors.blue);
        }),
      ),
    );
  }

  Widget _activityTile(
    BuildContext context,
    prescription,
    bool isDark,
    IconData icon,
    Color iconColor,
  ) {
    final dateStr = _formatDateLong(prescription.createdAt);
    final isLabReport = prescription.recordType == 'lab_report';
    final displayIcon = isLabReport ? Icons.description : icon;
    final typeLabel = isLabReport ? 'Lab Report' : 'Prescription';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? Constants.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrescriptionDetailScreen(prescription: prescription),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(displayIcon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prescription.aiSummary != null &&
                                        prescription.aiSummary!.isNotEmpty
                                    ? prescription.aiSummary!.length > 30
                                        ? '${prescription.aiSummary!.substring(0, 30)}...'
                                        : prescription.aiSummary!
                                    : typeLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  String _formatDateLong(DateTime date) {
    const months = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec';
    final i = date.month - 1;
    final m = months.split(' ')[i];
    return '${date.day} $m ${date.year}';
  }

  Widget _buildSecurityBadge(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              'END-TO-END ENCRYPTED',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your health data is secured using Aadhar-based authentication and 256-bit encryption.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  List<dynamic> _filterRecords(List<dynamic> list) {
    switch (_recordsFilter) {
      case _RecordsFilter.prescriptions:
        return list.where((p) => p.recordType != 'lab_report').toList();
      case _RecordsFilter.labReports:
        return list.where((p) => p.recordType == 'lab_report').toList();
      case _RecordsFilter.all:
        return list;
    }
  }

  Widget _buildRecordsView(
    BuildContext context,
    PrescriptionProvider prescriptionProvider,
    bool isDark,
  ) {
    final list = _filterRecords(prescriptionProvider.prescriptions);
    return RefreshIndicator(
      onRefresh: () async => _loadPrescriptions(),
      child: list.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: _buildEmptyActivity(isDark),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _recordsFilterChip('All', _RecordsFilter.all, isDark),
                        const SizedBox(width: 8),
                        _recordsFilterChip('Prescriptions', _RecordsFilter.prescriptions, isDark),
                        const SizedBox(width: 8),
                        _recordsFilterChip('Lab Reports', _RecordsFilter.labReports, isDark),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final p = list[index];
                      return _activityTile(
                        context,
                        p,
                        isDark,
                        Icons.receipt_long,
                        Constants.primaryColor,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _recordsFilterChip(String label, _RecordsFilter value, bool isDark) {
    final selected = _recordsFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _recordsFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Constants.primaryColor : (isDark ? Colors.white12 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Doctors',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your connected doctors will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    final user = authProvider.currentUser!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Constants.primaryColor.withOpacity(0.2),
              border: Border.all(color: Constants.primaryColor),
            ),
            child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(user.profileImageUrl!, fit: BoxFit.cover),
                  )
                : Icon(Icons.person, size: 48, color: Constants.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (user.aadharNumber != null) ...[
            const SizedBox(height: 8),
            Text(
              _maskAadhar(user.aadharNumber),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Constants.errorColor,
                side: const BorderSide(color: Constants.errorColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      decoration: BoxDecoration(
        color: (isDark ? Constants.backgroundDark : Constants.backgroundLight)
            .withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home, 'Home', isDark),
          _navItem(1, Icons.description, 'Records', isDark),
          _navItem(2, Icons.groups, 'Doctors', isDark),
          _navItem(3, Icons.person, 'Profile', isDark),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final selected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: selected
                ? Constants.primaryColor
                : (isDark ? Constants.textMutedDark : Constants.textMutedLight),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: selected
                  ? Constants.primaryColor
                  : (isDark ? Constants.textMutedDark : Constants.textMutedLight),
            ),
          ),
        ],
      ),
    );
  }
}
