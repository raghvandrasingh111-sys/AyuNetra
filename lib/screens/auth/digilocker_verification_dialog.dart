import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import 'dart:math';

class DigiLockerVerificationDialog extends StatefulWidget {
  const DigiLockerVerificationDialog({super.key});

  @override
  State<DigiLockerVerificationDialog> createState() =>
      _DigiLockerVerificationDialogState();
}

class _DigiLockerVerificationDialogState
    extends State<DigiLockerVerificationDialog> {
  int _currentStep = 0; // 0: Aadhar, 1: OTP, 2: Consent
  final _aadharController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _aadharController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      final text = _aadharController.text.trim();
      if (text.length != 12 || int.tryParse(text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 12-digit Aadhar number.'),
            backgroundColor: Constants.errorColor,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_otpController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 6-digit OTP.'),
            backgroundColor: Constants.errorColor,
          ),
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Finalize and return data
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      final random = Random();
      
      // Generate some dummy names/data based on Aadhar for deterministic feel
      final aadharStr = _aadharController.text.trim();
      final lastDigit = int.tryParse(aadharStr.substring(11)) ?? 0;
      
      final names = [
        'Aarav Patel', 'Diya Sharma', 'Vivaan Kumar', 'Ananya Singh', 
        'Advik Gupta', 'Saanvi Reddy', 'Reyansh Verma', 'Aadhya Iyer', 
        'Arjun Nair', 'Myra Joshi'
      ];
      
      final name = names[lastDigit % names.length];
      final age = (20 + random.nextInt(40)).toString();
      final gender = lastDigit % 2 == 0 ? 'Male' : 'Female';

      Navigator.of(context).pop({
        'aadhar': aadharStr,
        'name': name,
        'age': age,
        'gender': gender,
      });
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield,
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'DigiLocker',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Secure Government Verification',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),

            // Step Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(isDark),
            ),

            const SizedBox(height: 32),

            // Navigation
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // DigiLocker Blue
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentStep == 0
                            ? 'Send OTP'
                            : _currentStep == 1
                                ? 'Verify OTP'
                                : 'Grant Consent & Continue',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            
            if (_currentStep == 0) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    if (_currentStep == 0) {
      return Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your Aadhar Number to continue.',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aadharController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: InputDecoration(
              labelText: '12-Digit Aadhar',
              hintText: 'xxxx xxxx xxxx',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      return Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => setState(() => _currentStep = 0),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OTP sent to mobile linked with ***********${_aadharController.text.substring(8)}',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '000000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'For simulation, enter any 6 digits',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Constants.successColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Verification Successful',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Constants.successColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AyuNetra is requesting your consent to access your Name, Date of Birth, Gender, and Aadhar Number from DigiLocker.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      );
    }
  }
}
