import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/patient/prescription_detail_screen.dart';
import '../../screens/patient/add_prescription_screen.dart';
import 'patient_access_screen.dart';
import '../../models/user_model.dart';
import '../../models/prescription_model.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

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
    if (authProvider.currentUser != null) {
      prescriptionProvider.fetchPrescriptions(
        authProvider.currentUser!.id,
        'doctor',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final prescriptionProvider = Provider.of<PrescriptionProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Constants.backgroundDark : Constants.backgroundLight,
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Constants.primaryColor.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Constants.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadPrescriptions(),
              color: Constants.primaryColor,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(user, isDark, authProvider),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        // Desktop/Tablet layout adaptation
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _buildPatientOverviewCard(isDark),
                                        const SizedBox(height: 24),
                                        _buildRecentActivityList(isDark, prescriptionProvider),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        _buildQuickActionsCard(),
                                        const SizedBox(height: 24),
                                        _buildStatsCard(isDark),
                                        const SizedBox(height: 24),
                                        _buildUpcomingAppointmentsWidget(isDark),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Mobile layout
                              return Column(
                                children: [
                                  _buildPatientOverviewCard(isDark),
                                  const SizedBox(height: 24),
                                  _buildQuickActionsCard(),
                                  const SizedBox(height: 24),
                                  _buildStatsCard(isDark),
                                  const SizedBox(height: 24),
                                  _buildRecentActivityList(isDark, prescriptionProvider),
                                  const SizedBox(height: 24),
                                  _buildUpcomingAppointmentsWidget(isDark),
                                  const SizedBox(height: 80), // Padding for bottom nav
                                ],
                              );
                            }
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  Widget _buildSliverAppBar(UserModel? user, bool isDark, AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Constants.primaryColor.withOpacity(0.2), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : const NetworkImage('https://ui-avatars.com/api/?name=Doctor&background=10b748&color=fff'),
                    radius: 22,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Constants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Constants.backgroundDark : Constants.backgroundLight,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dr. ${user?.name ?? 'Ananya Sharma'}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Ophthalmologist Specialist',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Constants.primaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          tooltip: 'Logout',
          onPressed: () async {
            await authProvider.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPatientOverviewCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://ui-avatars.com/api/?name=Rajesh+Varma&background=e2e8f0&color=475569'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rajesh Varma',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'PATIENT ID: AN-9842',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Constants.textMutedLight,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Diabetes Type 2',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Monitoring Required',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // AI Summary Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Constants.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Constants.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI Patient Summary',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: 'Recent retinopathy screening shows '),
                      TextSpan(
                        text: 'stable vessel patterns',
                        style: TextStyle(
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '. HbA1c levels have trended downwards by 0.4% in the last 60 days. Recommend adjusting lens prescription slightly for low-light environments.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildVitalsCard('Intraocular', '14', 'mmHg', isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildVitalsCard('Visual Acuity', '20/25', '', isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildVitalsCard('Macula', 'Normal', '', isDark)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(String title, String value, String unit, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Constants.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Constants.textMutedLight,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColor,
              ),
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(bool isDark, PrescriptionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Patient Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Constants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.prescriptions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No recent activity',
                  style: GoogleFonts.inter(color: Constants.textMutedLight),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.prescriptions.length > 5 ? 5 : provider.prescriptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final prescription = provider.prescriptions[index];
                return _buildActivityItem(
                  icon: Icons.description_outlined,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  title: prescription.recordType.toUpperCase() == 'PRESCRIPTION' 
                      ? 'New Prescription Uploaded' 
                      : 'Record Uploaded',
                  subtitle: prescription.notes ?? 'Dr. Activity',
                  time: _formatDateStr(prescription.createdAt),
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PrescriptionDetailScreen(prescription: prescription),
                      ),
                    );
                  },
                );
              },
            ),
            
          // Mock data to show nice UI if nothing loaded yet to match template
          if (provider.prescriptions.isEmpty) ...[
            _buildActivityItem(
              icon: Icons.description_outlined,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.withOpacity(0.1),
              title: 'New Scan Uploaded',
              subtitle: 'Fundus Imaging • Sarah Jenkins',
              time: '2h ago',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: Icons.medical_services_outlined,
              iconColor: Constants.primaryColor,
              iconBgColor: Constants.primaryColor.withOpacity(0.1),
              title: 'Prescription Updated',
              subtitle: 'Post-Op Treatment • Michael Chen',
              time: '5h ago',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: Icons.notifications_active_outlined,
              iconColor: Colors.orange,
              iconBgColor: Colors.orange.withOpacity(0.1),
              title: 'Appointment Scheduled',
              subtitle: 'Follow-up • Priya Singh',
              time: 'Yesterday',
              isDark: isDark,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Constants.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Constants.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Constants.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              bottom: -40,
              right: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionButton(
                    icon: Icons.upload_file,
                    label: 'Upload New Prescription',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddPrescriptionScreen(),
                        ),
                      ).then((_) => _loadPrescriptions());
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionButton(
                    icon: Icons.lock_open,
                    label: 'Request Data Access',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PatientAccessScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATIENT GROWTH',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Constants.textMutedLight,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+24%',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Constants.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '8.2%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Compared to last month activity',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Constants.textMutedLight,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBarChartBar(0.4),
              _buildBarChartBar(0.6),
              _buildBarChartBar(0.3),
              _buildBarChartBar(0.8),
              _buildBarChartBar(0.95, isHighlighed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartBar(double percentage, {bool isHighlighed = false}) {
    return Container(
      width: 40,
      height: 80 * percentage,
      decoration: BoxDecoration(
        color: isHighlighed ? Constants.primaryColor : Constants.primaryColor.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsWidget(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S SCHEDULE",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Constants.textMutedLight,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildAppointmentItem('09:30', 'AM', 'Emily White', 'Glaucoma Checkup', true, isDark),
          const SizedBox(height: 16),
          _buildAppointmentItem('11:00', 'AM', 'David Miller', 'Cataract Consultation', false, isDark),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(
      String timeStr, String ampm, String name, String type, bool isPrimary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isPrimary ? Constants.primaryColor : Colors.grey[300]!,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Constants.textMutedLight,
                  ),
                ),
                Text(
                  ampm,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Constants.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Constants.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    // Only show on mobile
    if (MediaQuery.of(context).size.width > 800) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.backgroundDark.withOpacity(0.9) : Colors.white.withOpacity(0.9),
        border: Border(top: BorderSide(color: Constants.primaryColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 'Home', 0, isDark),
              _buildNavItem(Icons.group_outlined, 'Patients', 1, isDark),
              _buildNavItem(Icons.bar_chart_outlined, 'Stats', 2, isDark),
              _buildNavItem(Icons.settings_outlined, 'Settings', 3, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? Constants.primaryColor 
        : (isDark ? Colors.white54 : Colors.black54);
        
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateStr(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else if (duration.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
