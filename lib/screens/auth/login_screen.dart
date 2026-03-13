import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../doctor/doctor_dashboard.dart';
import '../patient/patient_dashboard.dart';
import 'digilocker_verification_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialUserType = 'patient',
    this.initialIsLogin = true,
  });

  final String initialUserType; // 'patient' | 'doctor'
  final bool initialIsLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryBlue = Color(0xFF1392EC);
  static const Color _bgLight = Color(0xFFF6F7F8);
  static const Color _bgDark = Color(0xFF101A22);
  static const Color _cardDark = Color(0xFF1A262F);
  static const Color _textDark = Color(0xFF0D161B);
  static const Color _textMuted = Color(0xFF4C799A);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _aadharController = TextEditingController();
  final _doctorRegNoController = TextEditingController();
  late String _selectedUserType;
  late bool _isLogin;
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  String? _digiLockerAge;
  String? _digiLockerGender;
  bool _isDigiLockerVerified = false;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.initialUserType;
    _isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _aadharController.dispose();
    _doctorRegNoController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _loginId {
    if (_selectedUserType == 'doctor') {
      return _doctorRegNoController.text.trim();
    }
    return _emailController.text.trim();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_isLogin) {
      success = await authProvider.signIn(
        _loginId,
        _passwordController.text,
        _selectedUserType,
      );
    } else {
      success = await authProvider.signUp(
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: _selectedUserType,
        email: _selectedUserType == 'patient' ? _emailController.text.trim() : null,
        aadharNumber: _selectedUserType == 'patient' ? _aadharController.text.trim() : null,
        doctorRegistrationNumber: _selectedUserType == 'doctor' ? _doctorRegNoController.text.trim() : null,
        age: _digiLockerAge,
        gender: _digiLockerGender,
      );
    }

    if (!mounted) return;

    if (success) {
      // For signup with email confirmation, user won't be authenticated yet
      if (!_isLogin && authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please check your email and click the confirmation link to complete signup.',
            ),
            backgroundColor: Constants.successColor,
            duration: Duration(seconds: 5),
          ),
        );
        // Switch to login mode so user can log in after confirming
        setState(() {
          _isLogin = true;
          _nameController.clear();
          _passwordController.clear();
          _aadharController.clear();
          _isDigiLockerVerified = false;
          _digiLockerAge = null;
          _digiLockerGender = null;
        });
        return;
      }

      if (_selectedUserType == 'patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Authentication failed'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  void _handleDigiLockerVerification() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DigiLockerVerificationDialog(),
    );

    if (result != null) {
      setState(() {
        _aadharController.text = result['aadhar'];
        _nameController.text = result['name'];
        _digiLockerAge = result['age'];
        _digiLockerGender = result['gender'];
        _isDigiLockerVerified = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DigiLocker verification successful! Fields auto-filled.'),
            backgroundColor: Constants.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : _textDark;
    final mutedColor = isDark ? Colors.blueGrey[300] : _textMuted;
    final surface = isDark ? _cardDark : Colors.white;
    final fieldFill = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F6F9);

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 34,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AyuNetra',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? 'Welcome back' : 'Create your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SegmentedRoleToggle(
                            isDark: isDark,
                            selected: _selectedUserType,
                            onChanged: (v) => setState(() => _selectedUserType = v),
                          ),
                          const SizedBox(height: 16),
                          if (!_isLogin) ...[
                            if (_selectedUserType == 'patient') ...[
                              InkWell(
                                onTap: _handleDigiLockerVerification,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF2563EB)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shield, color: Color(0xFF2563EB), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isDigiLockerVerified ? 'Verified with DigiLocker' : 'Auto-fill with DigiLocker',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _field(
                              context,
                              isDark: isDark,
                              fill: fieldFill,
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              readOnly: _isDigiLockerVerified,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_selectedUserType == 'patient') ...[
                            _field(
                              context,
                              isDark: isDark,
                              fill: fieldFill,
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!value.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!_isLogin) ...[
                              _field(
                                context,
                                isDark: isDark,
                                fill: fieldFill,
                                controller: _aadharController,
                                label: 'Aadhar Number',
                                hintText: '12-digit Aadhar number',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 14,
                                readOnly: _isDigiLockerVerified,
                                validator: (value) {
                                  if (!_isLogin && (value == null || value.isEmpty)) {
                                    return 'Please enter your Aadhar number';
                                  }
                                  if (!_isLogin && value != null) {
                                    final digits = value.replaceAll(RegExp(r'\D'), '');
                                    if (digits.length != 12) return 'Aadhar must be 12 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (_selectedUserType == 'doctor') ...[
                            _field(
                              context,
                              isDark: isDark,
                              fill: fieldFill,
                              controller: _doctorRegNoController,
                              label: 'Doctor Registration Number',
                              hintText: 'e.g. MCI12345 or DRN-2020-001',
                              icon: Icons.medical_services_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your registration number';
                                if (value.contains('@')) return 'Use your medical registration ID only, not an email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          _passwordField(
                            context,
                            isDark: isDark,
                            fill: fieldFill,
                          ),
                          const SizedBox(height: 18),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    textStyle: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(_isLogin ? 'Login' : 'Sign Up'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Login',
                              style: GoogleFonts.poppins(
                                color: mutedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedUserType == 'patient'
                          ? 'Patient login uses Email (and Aadhar on signup).'
                          : 'Doctor login uses your Registration Number (not email).',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(String type, String label) {
    final isSelected = _selectedUserType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Constants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required bool isDark,
    required Color fill,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: maxLength == null ? null : '',
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white.withValues(alpha: 0.80) : _textMuted,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white.withValues(alpha: 0.45) : _textMuted.withValues(alpha: 0.75),
        ),
      ),
      validator: validator,
    );
  }

  Widget _passwordField(
    BuildContext context, {
    required bool isDark,
    required Color fill,
  }) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white.withValues(alpha: 0.80) : _textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }
}

class _SegmentedRoleToggle extends StatelessWidget {
  const _SegmentedRoleToggle({
    required this.isDark,
    required this.selected,
    required this.onChanged,
  });

  static const Color _primaryBlue = Color(0xFF1392EC);

  final bool isDark;
  final String selected; // 'patient' | 'doctor'
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9);
    final pill = isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segItem(
              context,
              label: 'Patient',
              value: 'patient',
              selected: selected,
              pill: pill,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _segItem(
              context,
              label: 'Doctor',
              value: 'doctor',
              selected: selected,
              pill: pill,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segItem(
    BuildContext context, {
    required String label,
    required String value,
    required String selected,
    required Color pill,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = selected == value;
    return Material(
      color: isSelected ? pill : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(value),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isSelected ? _primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }
}
