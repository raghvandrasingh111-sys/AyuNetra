import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _notesController = TextEditingController();
  final _patientAadharController = TextEditingController();
  Uint8List? _selectedFileBytes;
  bool _isPdf = false;
  String? _selectedFileName;
  String _recordType = 'prescription'; // 'prescription' or 'lab_report'
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    _patientAadharController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedFileBytes = bytes;
          _isPdf = false;
          _selectedFileName = image.name;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedFileBytes = bytes;
          _isPdf = false;
          _selectedFileName = image.name;
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      if (mounted) {
        setState(() {
          _selectedFileBytes = bytes;
          _isPdf = true;
          _selectedFileName = result.files.single.name;
        });
      }
    }
  }

  Future<String> _uploadFile(Uint8List bytes, {required String extension}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);
    return prescriptionProvider.uploadFile(bytes, authProvider.currentUser!.id,
        fileExtension: extension);
  }

  Future<void> _savePrescription() async {
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image or PDF file'),
          backgroundColor: Constants.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String? patientId;
      if (authProvider.currentUser!.userType == 'doctor') {
        final aadhar = _patientAadharController.text.trim();
        if (aadhar.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter the patient\'s Aadhar number'),
                backgroundColor: Constants.errorColor,
              ),
            );
          }
          return;
        }
        patientId = await prescriptionProvider.getPatientIdByAadhar(aadhar);
        if (patientId == null && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No patient found with this Aadhar number. Ask them to sign up with this Aadhar first.'),
              backgroundColor: Constants.errorColor,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      } else {
        patientId = authProvider.currentUser!.id;
      }

      // Analyze with AI (images only; PDFs get fallback summary)
      Map<String, dynamic> aiSummary;
      final isLabReport = _recordType == 'lab_report';
      if (_isPdf) {
        aiSummary = {
          'summary': isLabReport
              ? 'Lab report PDF document. Review the attached file for details.'
              : 'PDF prescription document. Review the attached file for details.',
          'medications': <String>[],
          'dosage': isLabReport ? null : 'As prescribed',
          'instructions': isLabReport ? 'Review lab results' : 'Follow doctor\'s instructions',
        };
      } else {
        aiSummary = isLabReport
            ? {
                'summary': 'Lab report image. Review the attached file for details.',
                'medications': <String>[],
                'dosage': null,
                'instructions': 'Review lab results',
              }
            : await prescriptionProvider.analyzePrescriptionFromBytes(_selectedFileBytes!);
      }

      // Upload file to Supabase Storage (can fail with 403 if Storage policies missing)
      final extension = _isPdf ? 'pdf' : 'jpg';
      String imageUrl;
      try {
        imageUrl = await _uploadFile(_selectedFileBytes!, extension: extension);
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatUploadError(e)),
              backgroundColor: Constants.errorColor,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      // Create prescription record in database
      final success = await prescriptionProvider.createPrescription(
        doctorId: authProvider.currentUser!.id,
        patientId: patientId!,
        imageUrl: imageUrl,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        aiSummary: aiSummary,
        recordType: _recordType,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          Navigator.of(context).pop(); // Go back to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_recordType == 'lab_report'
                  ? 'Lab report added successfully!'
                  : 'Prescription added successfully!'),
              backgroundColor: Constants.primaryColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                prescriptionProvider.errorMessage ?? 'Failed to save prescription.',
              ),
              backgroundColor: Constants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatPrescriptionError(e)),
            backgroundColor: Constants.errorColor,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Message when Storage upload fails (403/RLS or network).
  static String _formatUploadError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('storageexception') ||
        s.contains('row-level security') ||
        s.contains('403') ||
        s.contains('unauthorized')) {
      return 'Something went wrong while uploading file. Check that Supabase Storage policies are set (SUPABASE_SETUP.md → Storage policies) and try again.';
    }
    return 'Something went wrong while uploading file. Please try again.';
  }

  Widget _recordTypeChip({required String label, required IconData icon, required String value}) {
    final selected = _recordType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected ? Constants.primaryColor : (isDark ? Colors.white12 : Colors.grey[200]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _recordType = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// User-friendly message for other save errors (e.g. DB insert).
  static String _formatPrescriptionError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('storageexception') ||
        (s.contains('row-level security') && s.contains('403'))) {
      return 'Upload blocked by server security settings. Add Storage policies in Supabase (see SUPABASE_SETUP.md) and try again.';
    }
    return 'Error: $e';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDoctor = authProvider.currentUser?.userType == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Constants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Record type: Prescription or Lab Report
            Text(
              'Record Type',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _recordTypeChip(
                    label: 'Prescription',
                    icon: Icons.medication,
                    value: 'prescription',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordTypeChip(
                    label: 'Lab Report',
                    icon: Icons.description,
                    value: 'lab_report',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Image Selection
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: const Text('Pick PDF File'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPdf();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedFileBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select image or PDF',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : _isPdf
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 80,
                                color: Colors.red[700],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFileName ?? 'PDF Document',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _selectedFileBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),

            // Patient Aadhar (required for doctors)
            if (isDoctor) ...[
              TextFormField(
                controller: _patientAadharController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: const InputDecoration(
                  labelText: 'Patient Aadhar Number',
                  hintText: '12-digit Aadhar of the patient',
                  prefixIcon: Icon(Icons.badge),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _savePrescription,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _recordType == 'lab_report' ? 'Save Lab Report' : 'Save Prescription',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
