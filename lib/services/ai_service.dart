import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import '../models/prescription_model.dart';

/// Analyzes prescription images using on-device OCR (ML Kit). No Gemini or API key required.
/// Patient briefing is generated locally from prescription data.
class AIService {
  /// Analyzes prescription from image bytes using on-device text recognition.
  /// Returns the same shape as before: summary, medications, dosage, instructions.
  Future<Map<String, dynamic>> analyzePrescriptionFromBytes(Uint8List imageBytes) async {
    if (kIsWeb) {
      return _fallbackSummary(
        'Prescription text extraction is available on the mobile app. '
        'On web, please enter medications and instructions manually.',
      );
    }

    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await _inputImageFromBytes(imageBytes);
      if (result == null) {
        return _fallbackSummary('Could not read image. Please try another photo.');
      }

      final inputImage = result.$1;
      final tempFile = result.$2;

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final fullText = recognizedText.text.trim();
        if (fullText.isEmpty) {
          return _fallbackSummary(
            'No text was found in this image. Please use a clearer photo of the prescription.',
          );
        }

        final parsed = _parsePrescriptionText(fullText);
        return {
          'summary': parsed['summary'] as String,
          'medications': parsed['medications'] as List<String>,
          'dosage': parsed['dosage'] as String,
          'instructions': parsed['instructions'] as String,
        };
      } finally {
        // Delete temp file only after ML Kit has finished reading it
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    } catch (e, stack) {
      return _fallbackSummary(
        'Unable to read prescription from image. Please enter details manually.',
        debug: '$e\n$stack',
      );
    }
  }

  /// Creates InputImage from bytes. On mobile, writes to a temp file so ML Kit can decode correctly.
  /// Returns (InputImage, File) - do NOT delete the file until after processImage() completes.
  Future<(InputImage, File)?> _inputImageFromBytes(Uint8List bytes) async {
    if (kIsWeb) return null;
    try {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/ayunetra_prescription_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(file.path);
      return (inputImage, file);
    } catch (_) {
      return null;
    }
  }

  /// Simple heuristics to turn raw OCR text into summary, medications, dosage, instructions.
  Map<String, dynamic> _parsePrescriptionText(String fullText) {
    final lines = fullText
        .split(RegExp(r'\n|\r'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final summary = fullText.length > 600 ? '${fullText.substring(0, 597)}...' : fullText;

    final medicationKeywords = RegExp(
      r'\b(mg|ml|tablet|tablets|capsule|capsules|syrup|drops|times\s*daily|od|bd|td|qid|once|twice)\b',
      caseSensitive: false,
    );
    final medicationLines = <String>[];
    for (final line in lines) {
      if (line.length < 2) continue;
      if (medicationKeywords.hasMatch(line) || RegExp(r'\d+\s*(mg|ml|tablet)', caseSensitive: false).hasMatch(line)) {
        medicationLines.add(line);
      }
    }

    String dosage = 'As prescribed';
    String instructions = 'Follow the prescription and your doctor\'s advice.';
    for (final line in lines) {
      final lower = line.toLowerCase();
      if ((lower.contains('dose') || lower.contains('dosage') || lower.contains('mg')) && dosage == 'As prescribed') {
        dosage = line;
      }
      if ((lower.contains('take') || lower.contains('before') || lower.contains('after') || lower.contains('daily'))) {
        instructions = line;
        break;
      }
    }
    if (medicationLines.isNotEmpty && instructions == 'Follow the prescription and your doctor\'s advice.') {
      instructions = medicationLines.take(3).join('. ');
    }

    return {
      'summary': summary,
      'medications': medicationLines.isEmpty ? <String>[] : medicationLines,
      'dosage': dosage,
      'instructions': instructions,
    };
  }

  static Map<String, dynamic> _fallbackSummary(String summary, {String? debug}) {
    if (debug != null && debug.isNotEmpty) {
      // ignore: avoid_print
      print('AIService.analyzePrescription: $debug');
    }
    return {
      'summary': summary,
      'medications': <String>[],
      'dosage': 'As prescribed',
      'instructions': 'Follow doctor\'s instructions',
    };
  }

  /// Legacy: analyze from image URL. Prefer [analyzePrescriptionFromBytes].
  Future<Map<String, dynamic>> analyzePrescription(String imageUrl) async {
    try {
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        return _fallbackSummary('Could not load image. Please try again.');
      }
      final imageBytes = imageResponse.bodyBytes;
      return analyzePrescriptionFromBytes(Uint8List.fromList(imageBytes));
    } catch (e) {
      return _fallbackSummary(
        'Unable to analyze prescription. Please review the image manually.',
        debug: e.toString(),
      );
    }
  }

  /// Generates a patient-friendly brief from prescription data (no AI, no API).
  Future<String> generatePatientBriefing(Prescription prescription) async {
    final m = prescription.medications;
    final meds = (m != null && m.isNotEmpty) ? m.join(', ') : 'Not specified';
    final dosage = prescription.dosage ?? 'As prescribed';
    final instructions = prescription.instructions ?? 'Follow doctor\'s instructions';
    final notes = prescription.notes ?? 'None';

    final buffer = StringBuffer();
    buffer.writeln('Here’s a simple summary of your prescription:\n');
    buffer.writeln('• Medications: $meds');
    buffer.writeln('• Dosage: $dosage');
    buffer.writeln('• How to take: $instructions');
    if (notes != 'None') buffer.writeln('• Notes: $notes');
    buffer.writeln('\nTake your medicines as directed. If you miss a dose, follow your doctor’s advice or the leaflet. For any doubt, ask your doctor or pharmacist.');
    return buffer.toString();
  }
}
