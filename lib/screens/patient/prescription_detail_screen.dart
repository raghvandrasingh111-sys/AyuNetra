import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../models/prescription_model.dart';
import '../../utils/constants.dart';
import '../../services/ai_service.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  final AIService _aiService = AIService();
  String? _patientBriefing;
  bool _isLoadingBriefing = false;

  @override
  void initState() {
    super.initState();
    _generateBriefing();
  }

  Future<void> _generateBriefing() async {
    setState(() {
      _isLoadingBriefing = true;
    });

    try {
      final briefing = await _aiService.generatePatientBriefing(widget.prescription);
      setState(() {
        _patientBriefing = briefing;
        _isLoadingBriefing = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBriefing = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool get _isPdfUrl => widget.prescription.imageUrl.toLowerCase().endsWith('.pdf');
  bool get _isLabReport => widget.prescription.isLabReport;

  // Extract JSON array from aiSummary if it exists
  List<dynamic>? _extractMarkers() {
    if (widget.prescription.aiSummary == null) return null;
    try {
      final regex = RegExp(r'\[.*\]', dotAll: true);
      final match = regex.firstMatch(widget.prescription.aiSummary!);
      if (match != null) {
        return jsonDecode(match.group(0)!);
      }
    } catch (e) {
      // Ignore JSON parsing errors
    }
    return null;
  }

  String _cleanBriefing(String? briefing) {
    if (briefing == null) return '';
    // Strip JSON out of the briefing if the AI returned it combined
    final regex = RegExp(r'\[.*\]', dotAll: true);
    return briefing.replaceAll(regex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDark ? const Color(0x800F172A) : Colors.white;
    final primaryColor = const Color(0xFF10B748);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6)).withOpacity(0.8),
                border: Border(bottom: BorderSide(color: primaryColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.05),
                      ),
                      child: Icon(Icons.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isLabReport ? 'Lab Report Details' : 'Prescription Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the flex row
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Card: Preview
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Preview Area
                          Container(
                            height: 160,
                            color: primaryColor.withOpacity(0.05),
                            padding: const EdgeInsets.all(16),
                            child: _isPdfUrl
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.description, size: 72, color: primaryColor),
                                      Positioned(
                                        bottom: 30, // Tweak as needed based on icon size
                                        right: MediaQuery.of(context).size.width / 2 - 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                        ),
                                      )
                                    ],
                                  )
                                : CachedNetworkImage(
                                    imageUrl: widget.prescription.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, err) => const Icon(Icons.error),
                                  ),
                          ),
                          // Details Area
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPdfUrl ? 'Document_Upload.pdf' : 'Scanned_Image.jpg',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Verified Record • ${_formatDate(widget.prescription.createdAt)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(widget.prescription.imageUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: Icon(_isPdfUrl ? Icons.visibility : Icons.image, color: Colors.white),
                                  label: Text(_isPdfUrl ? 'View PDF Report' : 'View Image', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide.none,
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AI Health Summary Title
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'AI Health Summary',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_isLabReport) ...[
                      // Render Lab Report Markers
                      _buildLabMarkers(isDark),
                    ] else ...[
                      // Render Normal Prescription Details
                      _buildPrescriptionDetails(isDark),
                    ],

                    const SizedBox(height: 24),

                    // Patient Briefing
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Patient Briefing',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingBriefing)
                            const CircularProgressIndicator()
                          else
                            Text(
                              _patientBriefing != null && _patientBriefing!.isNotEmpty
                                  ? _cleanBriefing(_patientBriefing)
                                  : 'Overall, your results have been uploaded successfully. Please consult with your doctor for further details and follow the instructions provided.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.6,
                                color: textColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabMarkers(bool isDark) {
    // If we have AI Summary JSON, parse it and render cards dynamically
    final markers = _extractMarkers();

    if (markers != null && markers.isNotEmpty) {
      return Column(
        children: markers.map((m) => _buildMarkerCard(
          isDark: isDark,
          title: m['markerName'] ?? 'Marker',
          status: m['status'] ?? 'UNKNOWN',
          value: m['value'] ?? '',
          unit: m['unit'] ?? '',
          referenceRange: m['referenceRange'] ?? '',
          interpretation: m['interpretation'],
        )).toList(),
      );
    }

    // Fallback if no JSON available
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x800F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.1)),
      ),
      child: Text(
        widget.prescription.aiSummary ?? 'No lab markers extracted. Awaiting detailed analysis.',
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildMarkerCard({
    required bool isDark,
    required String title,
    required String status,
    required String value,
    required String unit,
    required String referenceRange,
    String? interpretation,
  }) {
    Color statusColor;
    IconData icon;
    
    final s = status.toUpperCase();
    if (s == 'NORMAL') {
      statusColor = Constants.primaryColor;
      icon = Icons.bloodtype;
    } else if (s == 'HIGH' || s == 'ELEVATED') {
      statusColor = Colors.amber.shade600;
      icon = Icons.monitor_heart; // Changed from vital_signs
    } else if (s == 'LOW') {
      statusColor = Colors.blue.shade500;
      icon = Icons.opacity;
    } else {
      statusColor = Colors.grey.shade600;
      icon = Icons.science;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x800F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (interpretation != null && interpretation.isNotEmpty)
                  Text(
                    interpretation,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Value: $value $unit', style: GoogleFonts.inter(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Range: $referenceRange', style: GoogleFonts.inter(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                        ],
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

  Widget _buildPrescriptionDetails(bool isDark) {
    return Column(
      children: [
        if (widget.prescription.aiSummary != null && widget.prescription.aiSummary!.isNotEmpty)
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.description,
            title: 'Summary',
            content: widget.prescription.aiSummary!,
            color: Colors.blue,
          ),
        if (widget.prescription.medications != null && widget.prescription.medications!.isNotEmpty)
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.medication,
            title: 'Medications',
            content: widget.prescription.medications!.join(', '),
            color: Colors.amber.shade600,
          ),
        if (widget.prescription.dosage != null && widget.prescription.dosage!.isNotEmpty)
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.schedule,
            title: 'Dosage',
            content: widget.prescription.dosage!,
            color: Constants.primaryColor,
          ),
        if (widget.prescription.instructions != null && widget.prescription.instructions!.isNotEmpty)
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.assignment,
            title: 'Instructions',
            content: widget.prescription.instructions!,
            color: Colors.purple.shade400,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x800F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
