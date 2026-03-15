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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      backgroundColor: isDark ? const Color(0xFF0F172A) : Constants.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedNavIndex == 0) _buildHeader(context, authProvider),
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
      floatingActionButton: _selectedNavIndex == 0 || _selectedNavIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_selectedNavIndex == 0) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AISummaryScreen(
                        patient: authProvider.currentUser!,
                        records: prescriptionProvider.prescriptions,
                      ),
                    ),
                  );
                } else if (_selectedNavIndex == 1) {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const AddPrescriptionScreen(),
                        ),
                      )
                      .then((_) => _loadPrescriptions());
                }
              },
              backgroundColor: Constants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              elevation: 8,
              icon: Icon(
                _selectedNavIndex == 0 ? Icons.auto_awesome : Icons.add, 
                color: Colors.white
              ),
              label: Text(
                _selectedNavIndex == 0 ? 'AI Health Summary' : 'Add Record',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Constants.backgroundDark : Constants.backgroundLight).withOpacity(0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Constants.primaryColor.withOpacity(0.2), width: 2),
            ),
            child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(user.profileImageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, color: Constants.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AyuNetra',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _showSettingsOrLogout(context, authProvider);
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Constants.backgroundDark : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            user.name.split(' ').first,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your health dashboard is up to date.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int totalRecords, int recentVisits, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withOpacity(0.1),
                border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.folder_open, color: Constants.primaryColor, size: 24),
                      Text(
                        '+$recentVisits this month'.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Records',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRecords',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                      Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.black45, size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recent Visits',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$recentVisits',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
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

  Widget _buildUploadButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const AddPrescriptionScreen(),
                ),
              )
              .then((_) => _loadPrescriptions());
        },
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white, // slate-800
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Constants.primaryColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Constants.primaryColor.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Constants.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 28,
                              color: Constants.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload New Record',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add medical reports or prescriptions',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Constants.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          InkWell(
            onTap: () => setState(() => _selectedNavIndex = 1),
            child: Text(
              'View all',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Constants.primaryColor,
              ),
            ),
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
    IconData defaultIcon,
    Color defaultIconColor,
  ) {
    final dateStr = _formatDateLong(prescription.createdAt);
    final isLabReport = prescription.recordType == 'lab_report';
    final String title = isLabReport ? 'Lab Report' : 'Prescription';
    final IconData dispIcon = isLabReport ? Icons.science_outlined : Icons.receipt_long;
    final Color bgCol = isLabReport ? Colors.blue : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PrescriptionDetailScreen(prescription: prescription),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? bgCol.withOpacity(0.2) : bgCol.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(dispIcon, color: isDark ? bgCol.withAlpha(200) : bgCol, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.aiSummary != null && prescription.aiSummary!.isNotEmpty
                          ? prescription.aiSummary!.length > 25
                              ? '${prescription.aiSummary!.substring(0, 25)}...'
                              : prescription.aiSummary!
                          : title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Medical Record • AyuNetra',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 24,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ],
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
    var filtered = list;
    switch (_recordsFilter) {
      case _RecordsFilter.prescriptions:
        filtered = list.where((p) => p.recordType != 'lab_report').toList();
        break;
      case _RecordsFilter.labReports:
        filtered = list.where((p) => p.recordType == 'lab_report').toList();
        break;
      case _RecordsFilter.all:
        break;
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        final summary = (p.aiSummary ?? '').toLowerCase();
        return summary.contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildRecordsView(
    BuildContext context,
    PrescriptionProvider prescriptionProvider,
    bool isDark,
  ) {
    final list = _filterRecords(prescriptionProvider.prescriptions);
    return RefreshIndicator(
      onRefresh: () async => _loadPrescriptions(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white.withOpacity(0.8),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                      Text(
                        'Medical Records',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by doctor or clinic...',
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
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
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyActivity(isDark),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'RECENT UPLOADS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = list[index];
                    return _activityTile(
                      context,
                      p,
                      isDark,
                      Icons.receipt_long,
                      Constants.primaryColor,
                    );
                  },
                  childCount: list.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]
        ],
      ),
    );
  }

  Widget _recordsFilterChip(String label, _RecordsFilter value, bool isDark) {
    final selected = _recordsFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _recordsFilter = value),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: selected
              ? Constants.primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Constants.backgroundLight,
            border: Border(
              bottom: BorderSide(
                color: Constants.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                ),
                child: const Icon(Icons.settings, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Constants.primaryColor.withOpacity(0.2), width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(user.profileImageUrl!, fit: BoxFit.cover),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.primaryColor,
                                ),
                                child: const Icon(Icons.person, size: 60, color: Colors.white),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Constants.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F172A) : Constants.backgroundLight,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.verified, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: AYU-${user.id.hashCode.toString().substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade500,
                    side: BorderSide(color: Colors.red.withOpacity(0.2), width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 16),
                        child: Text(
                          'ACCOUNT SETTINGS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      _buildProfileMenuItem(
                        icon: Icons.person_outline,
                        color: Constants.primaryColor,
                        title: 'Personal Info',
                        subtitle: 'Manage your profile details',
                        isDark: isDark,
                      ),
                      _buildProfileMenuItem(
                        icon: Icons.security,
                        color: Colors.blue,
                        title: 'Security',
                        subtitle: 'Password and 2FA settings',
                        isDark: isDark,
                      ),
                      _buildProfileMenuItem(
                        icon: Icons.notifications_none,
                        color: Colors.orange,
                        title: 'Notifications',
                        subtitle: 'Control alert preferences',
                        isDark: isDark,
                      ),
                      _buildProfileMenuItem(
                        icon: Icons.help_outline,
                        color: Colors.purple,
                        title: 'Help & Support',
                        subtitle: 'Get assistance and FAQs',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? Constants.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 28, left: 16, right: 16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home, 'Home', isDark),
          _navItem(1, Icons.description, 'Records', isDark),
          _navItem(2, Icons.video_call, 'Consult', isDark),
          _navItem(3, Icons.account_circle, 'Profile', isDark),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final selected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected
                  ? Constants.primaryColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)), // slate-400
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Constants.primaryColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
