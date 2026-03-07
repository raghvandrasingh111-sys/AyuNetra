/// Record type: 'prescription' or 'lab_report'
class Prescription {
  final String id;
  final String doctorId;
  final String patientId;
  final String imageUrl;
  final String? notes;
  final String? aiSummary;
  final List<String>? medications;
  final String? dosage;
  final String? instructions;
  final String recordType; // 'prescription' or 'lab_report'
  final DateTime createdAt;
  final DateTime updatedAt;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.imageUrl,
    this.notes,
    this.aiSummary,
    this.medications,
    this.dosage,
    this.instructions,
    this.recordType = 'prescription',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLabReport => recordType == 'lab_report';

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      notes: json['notes'] as String?,
      aiSummary: json['ai_summary'] as String?,
      medications: json['medications'] != null
          ? List<String>.from((json['medications'] as List).map((e) => e.toString()))
          : null,
      dosage: json['dosage'] as String?,
      instructions: json['instructions'] as String?,
      recordType: json['record_type'] as String? ?? 'prescription',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.parse(v.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'image_url': imageUrl,
      'notes': notes,
      'ai_summary': aiSummary,
      'medications': medications,
      'dosage': dosage,
      'instructions': instructions,
      'record_type': recordType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
