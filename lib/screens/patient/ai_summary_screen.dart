import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/prescription_model.dart';
import '../../models/user_model.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';

class AISummaryScreen extends StatefulWidget {
  final UserModel patient;
  final List<Prescription> records;

  const AISummaryScreen({
    super.key,
    required this.patient,
    required this.records,
  });

  @override
  State<AISummaryScreen> createState() => _AISummaryScreenState();
}

class _AISummaryScreenState extends State<AISummaryScreen> {
  final GeminiService _geminiService = GeminiService();
  String? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _geminiService.generateHolisticSummary(
        widget.records,
        widget.patient.name,
      );
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate summary: \${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Constants.backgroundDark : Constants.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Health Summary'),
        backgroundColor: Constants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _summary != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateSummary,
              tooltip: 'Regenerate Summary',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Constants.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Analyzing medical records...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while the AI agent generates a holistic summary.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Constants.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generateSummary,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_summary == null || _summary!.isEmpty) {
      return Center(
        child: Text(
          'No summary could be generated.',
          style: GoogleFonts.inter(
            color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
          ),
        ),
      );
    }

    // Markdown success state
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Constants.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This summary is generated by an AI agent based on the uploaded prescriptions and lab reports. Always consult your doctor for medical advice.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          MarkdownBody(
            data: _summary!,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
              h1: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              h2: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColor,
              ),
              h3: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              listBullet: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              strong: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
