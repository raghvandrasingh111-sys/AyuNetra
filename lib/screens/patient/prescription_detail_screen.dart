import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../models/prescription_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

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
  Map<String, dynamic>? _parsedSummary;

  @override
  void initState() {
    super.initState();
    _parseSummary();
  }

  void _parseSummary() {
    final summaryStr = widget.prescription.aiSummary;
    if (summaryStr != null && summaryStr.isNotEmpty) {
      try {
        _parsedSummary = jsonDecode(summaryStr);
      } catch (e) {
        // Fallback for old records that just had text
        _parsedSummary = {
          'healthScore': 0,
          'riskLevel': 'Unknown',
          'insights': [{'iconType': 'description', 'text': summaryStr}],
          'indicators': []
        };
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool get _isLabReport => widget.prescription.isLabReport;

  void _downloadOrViewFile() async {
    final url = widget.prescription.imageUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Constants.backgroundDark : Constants.backgroundLight;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: (isDark ? Constants.backgroundDark : Constants.backgroundLight).withValues(alpha: 0.8),
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _isLabReport ? 'Lab Report Details' : 'Prescription Details',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: textColor),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Section with Gradient & Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Constants.primaryColor.withValues(alpha: 0.2),
                            Constants.primaryColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.0,
                                  colors: [
                                    Constants.primaryColor.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            child: Row(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Constants.primaryColor.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: user != null && user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: user.profileImageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 48, color: Constants.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.prescription.patientName ?? user?.name ?? 'Patient Name',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: AYU-${user?.id.hashCode.toString().substring(0, 8).toUpperCase() ?? 'XXXX'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Constants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Status and Date Bar (overlapping slightly via negative transform)
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TEST DATE',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: mutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(widget.prescription.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 32, width: 1, color: Constants.primaryColor.withValues(alpha: 0.2)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STATUS',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                      color: mutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Constants.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Verified',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Constants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 32, width: 1, color: Constants.primaryColor.withValues(alpha: 0.2)),
                              if (widget.prescription.imageUrl != null && widget.prescription.imageUrl!.isNotEmpty)
                                InkWell(
                                  onTap: _downloadOrViewFile,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Constants.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Constants.primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.download, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),

                      // --- DYNAMIC MANUAL VItALS & MEDS ---
                      if (widget.prescription.isManual || (widget.prescription.patientAge != null || widget.prescription.bloodPressure != null)) ...[
                        Row(
                          children: [
                            Icon(Icons.monitor_heart_outlined, color: Constants.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Patient Vitals & Details',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              if (widget.prescription.patientAge != null && widget.prescription.patientAge!.isNotEmpty)
                                _buildVitalItem('Age', '${widget.prescription.patientAge} Yrs', Icons.cake, isDark),
                              if (widget.prescription.gender != null && widget.prescription.gender!.isNotEmpty)
                                _buildVitalItem('Gender', widget.prescription.gender!, Icons.person_outline, isDark),
                              if (widget.prescription.patientHeight != null && widget.prescription.patientHeight!.isNotEmpty)
                                _buildVitalItem('Height', widget.prescription.patientHeight!, Icons.height, isDark),
                              if (widget.prescription.bloodPressure != null && widget.prescription.bloodPressure!.isNotEmpty)
                                _buildVitalItem('BP', widget.prescription.bloodPressure!, Icons.favorite_border, isDark),
                              if (widget.prescription.pulseRate != null && widget.prescription.pulseRate!.isNotEmpty)
                                _buildVitalItem('Pulse', '${widget.prescription.pulseRate} bpm', Icons.timeline, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (widget.prescription.medications != null && widget.prescription.medications!.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.medication_liquid, color: Constants.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Prescribed Medicines',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...widget.prescription.medications!.map((med) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Constants.primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    med,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                      // --- END MANUAL VITALS & MEDS ---

                      // --- DYNAMIC AI DASHBOARD WIDGET ---
                      if (_parsedSummary != null) ...[
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Constants.primaryColor),
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
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                isDark ? Constants.primaryColor.withValues(alpha: 0.1) : Constants.primaryColor.withValues(alpha: 0.05),
                                cardBgColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.2)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Stats Grid inside Summary
                                    if (_parsedSummary!['healthScore'] != null && _parsedSummary!['healthScore'] > 0)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.1)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('HEALTH SCORE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor)),
                                                      Icon(Icons.monitor_heart, size: 18, color: Constants.primaryColor),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 8,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                                    alignment: Alignment.centerLeft,
                                                    child: FractionallySizedBox(
                                                      widthFactor: (_parsedSummary!['healthScore'] as num).clamp(0, 100) / 100.0, 
                                                      child: Container(decoration: BoxDecoration(color: Constants.primaryColor, borderRadius: BorderRadius.circular(4)))
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text.rich(TextSpan(
                                                    children: [
                                                      TextSpan(text: '${_parsedSummary!['healthScore']}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                                                      TextSpan(text: '/100', style: GoogleFonts.inter(fontSize: 14, color: mutedColor)),
                                                    ],
                                                  )),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.1)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('RISK LEVEL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor)),
                                                      Icon(Icons.warning, size: 18, color: _getRiskColor(_parsedSummary!['riskLevel']?.toString() ?? '')),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 8,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                                    alignment: Alignment.centerLeft,
                                                    child: FractionallySizedBox(
                                                      widthFactor: _getRiskFactor(_parsedSummary!['riskLevel']?.toString() ?? ''), 
                                                      child: Container(decoration: BoxDecoration(color: _getRiskColor(_parsedSummary!['riskLevel']?.toString() ?? ''), borderRadius: BorderRadius.circular(4)))
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('${_parsedSummary!['riskLevel'] ?? 'Unknown'}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    
                                    if (_parsedSummary!['healthScore'] != null && _parsedSummary!['healthScore'] > 0)
                                      const SizedBox(height: 24),

                                    // Dynamic Insight list items
                                    if (_parsedSummary!['insights'] != null)
                                      ...(_parsedSummary!['insights'] as List).map((insight) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _buildInsightItem(
                                            isDark: isDark,
                                            icon: _getIconForType(insight['iconType']?.toString() ?? ''),
                                            iconColor: _getColorForType(insight['iconType']?.toString() ?? ''),
                                            textColor: textColor,
                                            text: insight['text']?.toString() ?? '',
                                          ),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Constants.primaryColor.withValues(alpha: 0.05) : Constants.primaryColor.withValues(alpha: 0.1),
                                  border: Border(top: BorderSide(color: Constants.primaryColor.withValues(alpha: 0.1))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '(${_parsedSummary!['summary'] ?? 'Analysis powered by AyuNetra AI Engine'})',
                                        style: GoogleFonts.inter(fontStyle: FontStyle.italic, fontSize: 10, color: mutedColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_parsedSummary!['indicators'] != null && (_parsedSummary!['indicators'] as List).isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Text(
                                'Key Indicators',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...(_parsedSummary!['indicators'] as List).map((ind) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProgressIndicatorCard(
                                isDark: isDark,
                                cardBgColor: cardBgColor,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                title: ind['title']?.toString() ?? 'Indicator',
                                value: ind['value']?.toString() ?? '',
                                markerOffset: (ind['markerOffset'] as num?)?.toDouble() ?? 0.5,
                              ),
                            );
                          }),
                        ],
                      ] else ...[
                        Row(
                          children: [
                            Icon(Icons.pending, color: mutedColor),
                            const SizedBox(width: 8),
                            Text(
                              'Awaiting Analysis Data',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // --- END DYNAMIC DASHBOARD ---
const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon, bool isDark) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Constants.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Constants.primaryColor),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressIndicatorCard({
    required bool isDark,
    required Color cardBgColor,
    required Color textColor,
    required Color mutedColor,
    required String title,
    required String value,
    required double markerOffset,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))),
              Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(flex: 25, child: Container(color: Colors.amber.withValues(alpha: 0.3))),
                  Expanded(
                    flex: 50,
                    child: Stack(
                      children: [
                        Container(color: Constants.primaryColor),
                        Align(
                          alignment: FractionalOffset(markerOffset, 0),
                          child: Container(width: 4, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 25, child: Container(color: Colors.redAccent.withValues(alpha: 0.3))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LOW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor)),
              Text('NORMAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Constants.primaryColor)),
              Text('HIGH', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: mutedColor)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    if (risk.toLowerCase() == 'low') return Constants.primaryColor;
    if (risk.toLowerCase() == 'moderate') return Colors.amber;
    if (risk.toLowerCase() == 'high') return Colors.redAccent;
    return Colors.grey;
  }

  double _getRiskFactor(String risk) {
    if (risk.toLowerCase() == 'low') return 0.25;
    if (risk.toLowerCase() == 'moderate') return 0.5;
    if (risk.toLowerCase() == 'high') return 0.85;
    return 0.1;
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'check': return Icons.check;
      case 'lightbulb': return Icons.lightbulb;
      case 'analytics': return Icons.analytics;
      case 'warning': return Icons.warning;
      case 'medication': return Icons.medication;
      default: return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'check': return Constants.primaryColor;
      case 'lightbulb': return Colors.amber.shade600;
      case 'analytics': return Colors.blue.shade400;
      case 'warning': return Colors.redAccent;
      case 'medication': return Colors.purple.shade400;
      default: return Constants.primaryColor;
    }
  }
}
