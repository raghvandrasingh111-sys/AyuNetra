import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/prescription_model.dart';
import '../utils/constants.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash', // A more cost-effective model
          apiKey: Constants.geminiApiKey,
        );

  /// Generates a holistic summary based on all patient records.
  Future<String> generateHolisticSummary(List<Prescription> records, String patientName) async {
    if (records.isEmpty) {
      return "No medical records found for this patient.";
    }

    // Sort records by creation date (newest first)
    final sortedRecords = List<Prescription>.from(records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final promptBuilder = StringBuffer();
    promptBuilder.writeln('You are an expert AI medical assistant acting as a summarization agent in a healthcare app.');
    promptBuilder.writeln('Your task is to provide a comprehensive, easy-to-understand, and holistic health summary for a patient named $patientName.');
    promptBuilder.writeln('Below is the chronological history of their medical records (prescriptions and lab reports).');
    promptBuilder.writeln('\n--- PATIENT RECORDS ---');

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final type = record.recordType == 'lab_report' ? 'Lab Report' : 'Prescription';
      final date = '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}';

      promptBuilder.writeln('\nRecord ${i + 1}: $type on $date');
      if (record.aiSummary != null && record.aiSummary!.isNotEmpty) {
        promptBuilder.writeln('Summary/Findings: ${record.aiSummary}');
      }
      if (record.medications != null && record.medications!.isNotEmpty) {
        promptBuilder.writeln('Medications: ${record.medications!.join(', ')}');
      }
      if (record.dosage != null && record.dosage!.isNotEmpty) {
        promptBuilder.writeln('Dosage: ${record.dosage}');
      }
      if (record.instructions != null && record.instructions!.isNotEmpty) {
        promptBuilder.writeln('Instructions: ${record.instructions}');
      }
      if (record.notes != null && record.notes!.isNotEmpty) {
        promptBuilder.writeln('Notes: ${record.notes}');
      }
    }

    promptBuilder.writeln('\n--- END OF RECORDS ---');
    promptBuilder.writeln('\nPlease generate a Markdown-formatted patient briefing with the following sections:');
    promptBuilder.writeln('1. **Health Overview**: A high-level summary of the patient\'s condition(s) based on the history.');
    promptBuilder.writeln('2. **Current Medications**: A synthesized list of active medications from recent prescriptions (avoiding duplicates if possible) and their dosages.');
    promptBuilder.writeln('3. **Recent Lab Results**: A summary of any recent lab report findings (if any).');
    promptBuilder.writeln('4. **Actionable Action Items/Advice**: Synthesized instructions for the patient to follow based on doctors\' advice.');
    promptBuilder.writeln('\nTone: Empathetic, professional, and clear. Do not provide new medical diagnoses; only summarize the provided data.');

    try {
      final content = [Content.text(promptBuilder.toString())];
      final response = await _model.generateContent(content);
      return response.text ?? 'Unable to generate summary at this time.';
    } catch (e) {
      return 'An error occurred while communicating with the AI agent: ${e.toString()}';
    }
  }

  /// Analyzes a lab report (image or PDF) and returns a structured summary
  /// with patient-friendly advice.
  Future<Map<String, dynamic>> analyzeLabReport(Uint8List fileBytes, bool isPdf) async {
    final mimeType = isPdf ? 'application/pdf' : 'image/jpeg';
    
    final prompt = '''
You are an expert AI medical assistant. Analyze the provided lab report and generate a simple, patient-friendly summary.
Do NOT output Markdown formatting like ```json. Output ONLY a valid JSON object with the following exact keys:
{
  "summary": "A 2-3 sentence overarching summary of the lab report findings in simple terms.",
  "instructions": "A bulleted list or 1-2 sentence advice on actionable next steps based on these results (e.g., 'Discuss elevated cholesterol with your doctor', 'Maintain healthy diet')."
}
If the document does not appear to be a lab report, return a summary stating that and empty instructions.
''';

    try {
      final content = [
        Content.multi([
          DataPart(mimeType, fileBytes),
          TextPart(prompt),
        ])
      ];
      
      final response = await _model.generateContent(content);
      final text = response.text?.trim() ?? '{}';
      
      // Clean up potential markdown formatting from the response
      String jsonStr = text;
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      final parsed = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
      
      return {
        'summary': parsed['summary'] ?? 'Lab report analyzed. Review the attached file for details.',
        'medications': <String>[],
        'dosage': null,
        'instructions': parsed['instructions'] ?? 'Review lab results with your doctor.',
      };
    } catch (e) {
      print('Error analyzing lab report: $e');
      return {
        'summary': 'Could not automatically analyze the lab report. Review the attached file for details.',
        'medications': <String>[],
        'dosage': null,
        'instructions': 'Review lab results with your doctor.',
      };
    }
  }
}
