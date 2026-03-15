import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/prescription_model.dart';
import '../utils/constants.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash', 
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

  /// Analyzes a medical record (image or PDF) and returns a structured summary
  /// formatted for the V2 detail screen UI.
  Future<Map<String, dynamic>> analyzeMedicalRecord(Uint8List fileBytes, bool isPdf) async {
    final mimeType = isPdf ? 'application/pdf' : 'image/jpeg';
    
    final prompt = '''
You are an expert AI medical assistant. Analyze the provided medical record (prescription or lab report) and extract key health data.
Do NOT output Markdown formatting like ```json. Output ONLY a valid JSON object with the following exact structure:
{
  "healthScore": <integer 0-100 representing overall health based on this document, use 85 if it's a routine prescription>,
  "riskLevel": "<Low, Moderate, or High>",
  "insights": [
    {"iconType": "<check, lightbulb, analytics, or warning>", "text": "<Actionable insight, observation, or medication instruction>"}
  ],
  "indicators": [
    {"title": "<e.g., Blood Glucose, Hemoglobin, Blood Pressure, etc.>", "value": "<value with unit>", "markerOffset": <float between 0.0 and 1.0 (0.5 is perfectly normal, 0.1 is very low, 0.9 is very high)>}
  ],
  "summary": "<2-3 sentence overview of the document>"
}
Make sure to extract up to 3-5 insights (these can include medication directions if it's a prescription) and any measurable indicators found in the document.
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
        // We encode the parsed JSON map into a string so it gets safely saved into the 'ai_summary' string column in the DB
        'summary': jsonEncode(parsed),
        'medications': <String>[],
        'dosage': null,
        'instructions': null,
      };
    } catch (e) {
      print('Error analyzing medical record: $e');
      final fallback = {
        "healthScore": 0,
        "riskLevel": "Unknown",
        "insights": [
          {"iconType": "warning", "text": "Could not automatically analyze the record. Please review the attached file manually."}
        ],
        "indicators": [],
        "summary": "Analysis failed."
      };
      return {
        'summary': jsonEncode(fallback),
        'medications': <String>[],
        'dosage': null,
        'instructions': null,
      };
    }
  }

  /// Analyzes a manual prescription record (typed by the user) and returns a structured summary
  /// formatted for the V2 detail screen UI.
  Future<Map<String, dynamic>> analyzeManualRecord({
    String? patientName,
    String? patientAge,
    String? bloodPressure,
    String? pulseRate,
    String? gender,
    List<String>? medications,
    String? notes,
  }) async {
    final patientDetails = [
      if (patientName != null && patientName.isNotEmpty) 'Name: $patientName',
      if (patientAge != null && patientAge.isNotEmpty) 'Age: $patientAge',
      if (gender != null && gender.isNotEmpty) 'Gender: $gender',
      if (bloodPressure != null && bloodPressure.isNotEmpty) 'BP: $bloodPressure',
      if (pulseRate != null && pulseRate.isNotEmpty) 'Pulse: $pulseRate',
    ].join(', ');

    final meds = medications?.join(', ') ?? 'None provided';
    final extraNotes = notes ?? 'None';

    final prompt = '''
You are an expert AI medical assistant. Analyze the provided manual prescription record details and extract key health data.
Patient Details: $patientDetails
Prescribed Medications: $meds
Doctor Notes: $extraNotes

Do NOT output Markdown formatting like ```json. Output ONLY a valid JSON object with the following exact structure:
{
  "healthScore": <integer 0-100 representing overall health based on this document, use 85 if it's a routine prescription>,
  "riskLevel": "<Low, Moderate, or High based on vitals and medications>",
  "insights": [
    {"iconType": "<check, lightbulb, analytics, or warning>", "text": "<Actionable insight, observation, or medication instruction based on the data>"}
  ],
  "indicators": [
    {"title": "<e.g., Blood Pressure, Pulse, etc. extracted from Patient Details>", "value": "<value with unit>", "markerOffset": <float between 0.0 and 1.0 (0.5 is perfectly normal, 0.1 is very low, 0.9 is very high)>}
  ],
  "summary": "<2-3 sentence overview of this manual record prescription>"
}
Make sure to extract up to 3-5 insights (these can include medication directions) and map any provided vitals into the indicators array.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text?.trim() ?? '{}';
      
      String jsonStr = text;
      if (jsonStr.startsWith('```json')) jsonStr = jsonStr.substring(7);
      else if (jsonStr.startsWith('```')) jsonStr = jsonStr.substring(3);
      if (jsonStr.endsWith('```')) jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      
      final parsed = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
      
      return {
        'summary': jsonEncode(parsed),
        'medications': medications ?? <String>[],
        'dosage': null,
        'instructions': null,
      };
    } catch (e) {
      print('Error analyzing manual record: $e');
      final fallback = {
        "healthScore": 0,
        "riskLevel": "Unknown",
        "insights": [
          {"iconType": "warning", "text": "Could not automatically analyze the manual record."}
        ],
        "indicators": [],
        "summary": "Analysis failed."
      };
      return {
        'summary': jsonEncode(fallback),
        'medications': medications ?? <String>[],
        'dosage': null,
        'instructions': null,
      };
    }
  }

  // Backwards compatibility alias
  Future<Map<String, dynamic>> analyzeLabReport(Uint8List fileBytes, bool isPdf) async {
    return analyzeMedicalRecord(fileBytes, isPdf);
  }
}
