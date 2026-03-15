import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

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
    final url = p.imageUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file attached to this record')),
        );
      }
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
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
      backgroundColor: bg.withOpacity(0.95),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
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
            Icons.ios_share_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 22,
          ),
          onPressed: _shareHistory,
        ),
        const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Constants.primaryColor.withOpacity(0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 60,
                height: 60,
                child: patient.profileImageUrl != null &&
                        patient.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: patient.profileImageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Constants.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Constants.primaryColor,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 20),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Patient',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _maskAadhar(patient.aadharNumber),
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Constants.primaryColor : (isDark ? cardColor.withOpacity(0.5) : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: selected ? Border.all(color: Constants.primaryColor) : Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Constants.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
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
    
    // Parse the AI summary to extract insight if available
    String summaryText = isLabReport ? 'Lab Report' : 'Prescription Document';
    if (p.aiSummary != null && p.aiSummary!.isNotEmpty) {
      summaryText = p.aiSummary!;
      if (summaryText.startsWith('{')) {
        try {
          final Map<String, dynamic> data = jsonDecode(summaryText);
          summaryText = data['summary'] ?? (isLabReport ? 'Lab Report' : 'Prescription Document');
        } catch (_) {}
      }
    }
    
    final title = summaryText.length > 40 ? '${summaryText.substring(0, 40)}...' : summaryText;
    final iconColor = isLabReport ? Colors.blue : Constants.primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Constants.backgroundDark : Constants.backgroundLight,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 160,
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLabReport ? 'LAB REPORT' : 'PRESCRIPTION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: iconColor,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(p.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white54.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medical_services_rounded,
                          size: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doctorName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PrescriptionDetailScreen(prescription: p),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_red_eye_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'View Details',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Constants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _downloadPrescription(p),
                            icon: const Icon(Icons.file_download_outlined),
                            color: Constants.primaryColor,
                            iconSize: 20,
                            tooltip: 'Download Original',
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filter == _RecordFilter.reports
                    ? Icons.description_outlined
                    : _filter == _RecordFilter.visits
                        ? Icons.calendar_today_outlined
                        : Icons.medical_services_outlined,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _filter == _RecordFilter.reports
                  ? 'No lab reports found'
                  : _filter == _RecordFilter.visits
                      ? 'No visit history'
                      : 'No medical records',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _filter == _RecordFilter.all || _filter == _RecordFilter.prescriptions
                  ? 'There are no prescriptions or lab reports matching this filter.'
                  : 'This patient does not have any records in this category yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
