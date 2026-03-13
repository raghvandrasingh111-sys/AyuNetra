import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';
import '../patient/prescription_detail_screen.dart';

/// Filter tabs for medical history.
enum _RecordFilter { all, prescriptions, reports, visits }

class PatientMedicalHistoryScreen extends StatefulWidget {
  final String patientId;

  const PatientMedicalHistoryScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientMedicalHistoryScreen> createState() =>
      _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState
    extends State<PatientMedicalHistoryScreen> {
  UserModel? _patient;
  List<Prescription> _prescriptions = [];
  final Map<String, String> _doctorNames = {};
  _RecordFilter _filter = _RecordFilter.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final rx = context.read<PrescriptionProvider>();

    final patient = await auth.getProfileById(widget.patientId);
    final list = await rx.fetchPatientHistoryAsDoctor(widget.patientId);

    if (!mounted) return;

    final doctorIds = list.map((p) => p.doctorId).toSet();
    final names = <String, String>{};
    for (final id in doctorIds) {
      final doc = await auth.getProfileById(id);
      if (doc != null) names[id] = doc.name;
    }

    setState(() {
      _patient = patient;
      _prescriptions = list;
      _doctorNames.addAll(names);
      _isLoading = false;
    });
  }

  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.length < 4) return 'XXXX-XXXX-XXXX';
    final digits = aadhar.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) return 'XXXX-XXXX-XXXX';
    return 'XXXX-XXXX-${digits.substring(8)}';
  }

  String _formatDate(DateTime d) {
    const months =
        'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec';
    final m = months.split(' ')[d.month - 1];
    return '$m ${d.day}, ${d.year}';
  }

  Future<void> _shareHistory() async {
    if (_patient == null) return;
    final buffer = StringBuffer();
    buffer.writeln('Medical History Summary - ${_patient!.name}');
    buffer.writeln('Aadhar: ${_maskAadhar(_patient!.aadharNumber)}');
    buffer.writeln('');
    buffer.writeln('Records (${_prescriptions.length}):');
    for (final p in _prescriptions) {
      buffer.writeln(
          '• ${_formatDate(p.createdAt)}: ${p.aiSummary ?? 'Prescription'}');
    }
    await Share.share(buffer.toString(),
        subject: 'Medical History - ${_patient!.name}');
  }

  Future<void> _downloadPrescription(Prescription p) async {
    final url = Uri.parse(p.imageUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document')),
      );
    }
  }

  List<Prescription> get _filteredPrescriptions {
    switch (_filter) {
      case _RecordFilter.reports:
        return _prescriptions.where((p) => p.recordType == 'lab_report').toList();
      case _RecordFilter.visits:
        return [];
      case _RecordFilter.prescriptions:
        return _prescriptions.where((p) => p.recordType != 'lab_report').toList();
      case _RecordFilter.all:
        return _prescriptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Constants.backgroundDark : Constants.backgroundLight;
    final cardColor = isDark ? Constants.cardDark : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(context, isDark),
                SliverToBoxAdapter(
                  child: _buildProfileCard(
                    context,
                    isDark,
                    cardColor,
                    borderColor,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildFilterTabs(context, isDark, cardColor, borderColor),
                ),
                if (_filteredPrescriptions.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context, isDark),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = _filteredPrescriptions[index];
                          return _buildTimelineCard(
                            context,
                            p,
                            isDark,
                            cardColor,
                            borderColor,
                            index == _filteredPrescriptions.length - 1,
                          );
                        },
                        childCount: _filteredPrescriptions.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final bg = isDark ? Constants.backgroundDark : Constants.backgroundLight;
    return SliverAppBar(
      pinned: true,
      backgroundColor: bg.withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: isDark ? Colors.white : Colors.black87,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Medical History',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share,
            color: Constants.primaryColor,
          ),
          onPressed: _shareHistory,
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    final patient = _patient;
    if (patient == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 64,
              height: 64,
              child: patient.profileImageUrl != null &&
                      patient.profileImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: patient.profileImageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Constants.primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Constants.primaryColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Patient',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _maskAadhar(patient.aadharNumber),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: Constants.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AADHAR VERIFIED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Constants.successColor,
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

  Widget _buildFilterTabs(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All Records', _RecordFilter.all, isDark, cardColor, borderColor),
            const SizedBox(width: 8),
            _filterChip('Prescriptions', _RecordFilter.prescriptions, isDark, cardColor, borderColor),
            const SizedBox(width: 8),
            _filterChip('Reports', _RecordFilter.reports, isDark, cardColor, borderColor),
            const SizedBox(width: 8),
            _filterChip('Visits', _RecordFilter.visits, isDark, cardColor, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    _RecordFilter value,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Constants.primaryColor : cardColor,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Constants.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    Prescription p,
    bool isDark,
    Color cardColor,
    Color borderColor,
    bool isLast,
  ) {
    final doctorName = _doctorNames[p.doctorId] ?? 'Doctor';
    final isLabReport = p.recordType == 'lab_report';
    final title = p.aiSummary != null && p.aiSummary!.isNotEmpty
        ? (p.aiSummary!.length > 30 ? '${p.aiSummary!.substring(0, 30)}...' : p.aiSummary!)
        : (isLabReport ? 'Lab Report' : 'Prescription');
    const iconColor = Constants.primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Constants.backgroundDark : Constants.backgroundLight,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isLabReport ? Icons.description : Icons.medication,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  margin: const EdgeInsets.only(top: 4),
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLabReport ? 'LAB REPORT' : 'PRESCRIPTION',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Constants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(p.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$doctorName • ${isLabReport ? 'Lab Report' : 'Prescription'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PrescriptionDetailScreen(prescription: p),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 18,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View Document',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Constants.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _downloadPrescription(p),
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.download,
                              color: Constants.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == _RecordFilter.reports
                  ? Icons.description_outlined
                  : _filter == _RecordFilter.visits
                      ? Icons.calendar_today_outlined
                      : Icons.medical_services_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _filter == _RecordFilter.reports
                  ? 'No lab reports yet'
                  : _filter == _RecordFilter.visits
                      ? 'No visit records yet'
                      : 'No records found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filter == _RecordFilter.all || _filter == _RecordFilter.prescriptions
                  ? 'Prescriptions will appear here when added.'
                  : 'This section is for future lab reports and visit notes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
