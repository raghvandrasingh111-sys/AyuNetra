/// Record type: 'prescription' or 'lab_report'
class Prescription {
  final String id;
  final String doctorId;
  final String patientId;
  final String? imageUrl;
  final String? notes;
  final String? aiSummary;
  final List<String>? medications;
  final String? dosage;
  final String? instructions;
  final String recordType; // 'prescription' or 'lab_report'
  
  // Manual Prescription Fields
  final String? patientName;
  final String? patientAge;
  final String? patientHeight;
  final String? bloodPressure;
  final String? pulseRate;
  final String? gender;
  final bool isManual;

  final DateTime createdAt;
  final DateTime updatedAt;

  Prescription({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.imageUrl,
    this.notes,
    this.aiSummary,
    this.medications,
    this.dosage,
    this.instructions,
    this.recordType = 'prescription',
    this.patientName,
    this.patientAge,
    this.patientHeight,
    this.bloodPressure,
    this.pulseRate,
    this.gender,
    this.isManual = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLabReport => recordType == 'lab_report';

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      notes: json['notes'] as String?,
      aiSummary: json['ai_summary'] as String?,
      medications: json['medications'] != null
          ? List<String>.from((json['medications'] as List).map((e) => e.toString()))
          : null,
      dosage: json['dosage'] as String?,
      instructions: json['instructions'] as String?,
      recordType: json['record_type'] as String? ?? 'prescription',
      patientName: json['patient_name'] as String?,
      patientAge: json['patient_age'] as String?,
      patientHeight: json['patient_height'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      pulseRate: json['pulse_rate'] as String?,
      gender: json['gender'] as String?,
      isManual: json['is_manual'] as bool? ?? false,
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
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_height': patientHeight,
      'blood_pressure': bloodPressure,
      'pulse_rate': pulseRate,
      'gender': gender,
      'is_manual': isManual,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
