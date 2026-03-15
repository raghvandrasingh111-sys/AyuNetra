import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../services/gemini_service.dart';
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
  bool _isManualEntry = false;
  
  // Manual Entry Controllers
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientHeightController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _pulseRateController = TextEditingController();
  String? _selectedGender;
  
  // Manual Medicines
  final List<Map<String, String>> _manualMedicines = [];
  final _medNameController = TextEditingController();
  final _medTimeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    _patientAadharController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientHeightController.dispose();
    _bloodPressureController.dispose();
    _pulseRateController.dispose();
    _medNameController.dispose();
    _medTimeController.dispose();
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
    if (!_isManualEntry && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image or PDF file', style: GoogleFonts.inter()),
          backgroundColor: Constants.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_isManualEntry && _patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter patient name for manual entry', style: GoogleFonts.inter()),
          backgroundColor: Constants.errorColor,
          behavior: SnackBarBehavior.floating,
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
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Constants.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(color: Constants.primaryColor),
        ),
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
              SnackBar(
                content: Text('Please enter the patient\'s Aadhar number', style: GoogleFonts.inter()),
                backgroundColor: Constants.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        patientId = await prescriptionProvider.getPatientIdByAadhar(aadhar);
        if (patientId == null && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No patient found with this Aadhar number. Ask them to sign up with this Aadhar first.', style: GoogleFonts.inter()),
              backgroundColor: Constants.errorColor,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        patientId = authProvider.currentUser!.id;
      }

      Map<String, dynamic>? aiSummary;
      String? imageUrl;

      // Prepare manual medications list
      List<String> manualMedsList = _manualMedicines.map((m) => '${m['name']} (${m['time']})').toList();

      if (!_isManualEntry) {
        // Analyze with AI using Gemini for all records (both PDF and Images)
        aiSummary = await GeminiService().analyzeMedicalRecord(_selectedFileBytes!, _isPdf);

        // Upload file to Supabase Storage
        final extension = _isPdf ? 'pdf' : 'jpg';
        try {
          imageUrl = await _uploadFile(_selectedFileBytes!, extension: extension);
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_formatUploadError(e), style: GoogleFonts.inter()),
                backgroundColor: Constants.errorColor,
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } else {
        // Connect manual entry to AI
        aiSummary = await GeminiService().analyzeManualRecord(
          patientName: _patientNameController.text.trim(),
          patientAge: _patientAgeController.text.trim(),
          bloodPressure: _bloodPressureController.text.trim(),
          pulseRate: _pulseRateController.text.trim(),
          gender: _selectedGender,
          medications: manualMedsList.isEmpty ? null : manualMedsList,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      final success = await prescriptionProvider.createPrescription(
        doctorId: authProvider.currentUser!.id,
        patientId: patientId!,
        imageUrl: imageUrl,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        aiSummary: aiSummary,
        recordType: _recordType,
        isManual: _isManualEntry,
        patientName: _patientNameController.text.trim(),
        patientAge: _patientAgeController.text.trim(),
        patientHeight: _patientHeightController.text.trim(),
        bloodPressure: _bloodPressureController.text.trim(),
        pulseRate: _pulseRateController.text.trim(),
        gender: _selectedGender,
        manualMedications: manualMedsList.isEmpty ? null : manualMedsList,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          Navigator.of(context).pop(); // Go back to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_recordType == 'lab_report'
                  ? 'Lab report added successfully!'
                  : 'Prescription added successfully!', style: GoogleFonts.inter()),
              backgroundColor: Constants.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                prescriptionProvider.errorMessage ?? 'Failed to save prescription.', style: GoogleFonts.inter()
              ),
              backgroundColor: Constants.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatPrescriptionError(e), style: GoogleFonts.inter()),
            backgroundColor: Constants.errorColor,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
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
      color: selected ? Constants.primaryColor : (isDark ? Colors.white12 : Colors.grey[100]),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _recordType = value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Constants.primaryColor : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
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
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryMethodChip({required String label, required bool isManual}) {
    final selected = _isManualEntry == isManual;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: selected ? Constants.primaryColor : (isDark ? Colors.white12 : Colors.grey[100]),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _isManualEntry = isManual),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Constants.primaryColor : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField('Patient Name', _patientNameController, Icons.person_outline, isDark),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Age (Yrs)', _patientAgeController, Icons.calendar_today, isDark, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
                decoration: _inputDeco('Gender', Icons.people_outline, isDark),
                dropdownColor: isDark ? Constants.cardDark : Colors.white,
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Height (cm/ft)', _patientHeightController, Icons.height, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Blood Press. (e.g. 120/80)', _bloodPressureController, Icons.favorite_border, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Pulse (bpm)', _pulseRateController, Icons.monitor_heart_outlined, isDark, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Prescription Medicines',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Constants.textMutedLight,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        // Medicines List
        ..._manualMedicines.map((med) => _buildMedicineTile(med, isDark)),
        
        // Add Medicine Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField('Medicine Name', _medNameController, Icons.medication_liquid, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField('Time/Dosage', _medTimeController, Icons.access_time, isDark),
            ),
            const SizedBox(width: 12),
            Container(
              height: 54, // Match typical text field height
              width: 54,
              decoration: BoxDecoration(
                color: Constants.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  if (_medNameController.text.trim().isNotEmpty) {
                    setState(() {
                      _manualMedicines.add({
                        'name': _medNameController.text.trim(),
                        'time': _medTimeController.text.trim().isNotEmpty ? _medTimeController.text.trim() : 'As directed',
                      });
                      _medNameController.clear();
                      _medTimeController.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineTile(Map<String, String> med, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name'] ?? '',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                Text(
                  med['time'] ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: Constants.textMutedLight),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _manualMedicines.remove(med);
              });
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Constants.primaryColor, size: 20),
      filled: true,
      fillColor: isDark ? Colors.black12 : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
      decoration: _inputDeco(label, icon, isDark),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Constants.backgroundDark : Constants.backgroundLight,
      appBar: AppBar(
        title: Text('Add New Record', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Constants.cardDark.withOpacity(0.4) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Constants.primaryColor.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Record type: Prescription or Lab Report
                  Text(
                    'Record Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Constants.textMutedLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  
                  // Entry Mode toggle (only if prescription)
                  if (_recordType == 'prescription') ...[
                    Text(
                      'Entry Method',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Constants.textMutedLight,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _entryMethodChip(label: 'Upload File', isManual: false)),
                        const SizedBox(width: 12),
                        Expanded(child: _entryMethodChip(label: 'Manual Entry', isManual: true)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (!_isManualEntry || _recordType != 'prescription') ...[
                    // Image Selection
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: isDark ? Constants.cardDark : Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Constants.primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.photo_library, color: Constants.primaryColor),
                                    ),
                                    title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage();
                                    },
                                  ),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.blue),
                                    ),
                                    title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _takePhoto();
                                    },
                                  ),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    ),
                                    title: Text('Pick PDF File', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickPdf();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black12 : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _selectedFileBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Constants.primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 40,
                                      color: Constants.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to select image or PDF',
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                                        color: Colors.red[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          _selectedFileName ?? 'PDF Document',
                                          style: GoogleFonts.inter(
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          _selectedFileBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(0.3),
                                          child: const Center(
                                            child: Icon(Icons.edit, color: Colors.white, size: 32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ],

                  // Manual Entry Fields
                  if (_isManualEntry && _recordType == 'prescription') ...[
                    _buildManualEntryForm(isDark),
                  ],

                  const SizedBox(height: 24),

                  // Patient Aadhar (required for doctors)
                  if (isDoctor) ...[
                    Text(
                      'Patient Assignment',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Constants.textMutedLight,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _patientAadharController,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Patient Aadhar Number',
                        hintText: '12-digit Aadhar of the patient',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Constants.primaryColor),
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  Text(
                    'Additional Context',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Constants.textMutedLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Case Notes (Optional)',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60), // Align to top
                        child: Icon(Icons.note_alt_outlined, color: Constants.primaryColor),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _savePrescription,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _recordType == 'lab_report' ? 'Upload & Analyze Report' : 'Upload & Analyze Prescription',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
