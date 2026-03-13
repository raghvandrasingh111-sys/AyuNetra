import 'dart:io';

void main() {
  final file = File('lib/screens/patient/prescription_detail_screen.dart');
  String content = file.readAsStringSync();

  // Add initState and parsing logic
  final stateStart = content.indexOf('class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {');
  
  final newClassContent = '''
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
''';
  
  content = content.replaceFirst('class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {', newClassContent);

  // We need to replace the hardcoded AI Dashboard Widget inside build()
  // Finding the start of "// AI Dashboard Widget" and the end of Key Indicators section.
  
  final startToken = '// AI Health Summary Title'; 
  final endToken = 'const SizedBox(height: 40),'; // right before the end of the column
  
  final startIndex = content.indexOf(startToken);
  final endIndex = content.indexOf(endToken);
  
  if (startIndex != -1 && endIndex != -1) {
    final uiReplacement = '''
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
                                                      TextSpan(text: '\${_parsedSummary!['healthScore']}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
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
                                                  Text('\${_parsedSummary!['riskLevel'] ?? 'Unknown'}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                        '(\${_parsedSummary!['summary'] ?? 'Analysis powered by AyuNetra AI Engine'})',
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
                          }).toList(),
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
''';
    
    content = content.replaceRange(startIndex, endIndex, uiReplacement);
  } else {
    print("Could not find start or end token for replacement!");
    exit(1);
  }

  // Inject helper methods at the end of the class
  final helperMethods = '''

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
''';

  content = content.replaceFirst('}\n', helperMethods, content.lastIndexOf('}'));

  file.writeAsStringSync(content);
  print('Successfully updated prescription_detail_screen.dart!');
}
