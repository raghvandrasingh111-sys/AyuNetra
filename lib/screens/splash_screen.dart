import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'patient/patient_dashboard.dart';
import 'doctor/doctor_dashboard.dart';

const Color _primaryColor = Color(0xFF10B748);
const Color _bgLight = Color(0xFFF6F8F6);
const Color _bgDark = Color(0xFF102216);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadCurrentUser();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      final userType = authProvider.currentUser!.userType;
      if (userType == 'patient') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorDashboard()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    final Color bgColor1 = isDark ? _bgDark : _bgLight;
    final Color bgColor2 = isDark ? const Color(0xFF0F172A) : Colors.white; // slate-900 is 0xFF0F172A

    final Color textColorPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A); // slate-100 : slate-900
    final Color textColorSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // slate-400 : slate-500
    final Color containerBg = isDark ? const Color(0xFF1E293B) : Colors.white; // slate-800 : white

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor1, bgColor2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background texture
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.05 : 0.03,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAyclH2HTwG8zvjbe3Zn01hV24BeV7LO1DTegpXD-KfyJ_3-aFcCkXfTG3siL-pWyMGE73Crt0ExzVjlRV9rr2bf6_KXIsfZV3WaJwY45XHgqmALrpVuPmcOKJa_GFXfXFkFlCbYjN-ezEhVKCsadICDu5tny-S_2XpPo5o9I0-hcnjsXNdsC1Y09qo-K8mXbpiZNREfTbPHP0aQXKJLnsAMMgoHG6vzFvwLxkUSjdIU82xHn6XtrCL8R_59bMzY-FcTfYy_SJ1HK3B',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
            
            // Top Right Blur Element
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Left Blur Element
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.1),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.2),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Centered Logo
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: containerBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 72,
                            color: _primaryColor,
                          ),
                        ),
                        // Absolute leaf overlay
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: containerBg, width: 4),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Typography Area
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Ayu',
                        style: TextStyle(color: textColorPrimary),
                      ),
                      const TextSpan(
                        text: 'Netra',
                        style: TextStyle(color: _primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Personal Health Companion',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColorSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            // Bottom Loading & Branding
            Positioned(
              bottom: 48,
              left: 32,
              right: 32,
              child: Center(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading Bar Component
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'INITIALIZING',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      '${(_progressAnimation.value * 100).toInt()}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textColorSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(isDark ? 0.05 : 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Footer Copyright
                      Text(
                        '© 2024 AyuNetra Health',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.4), shape: BoxShape.circle),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.4), shape: BoxShape.circle),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.4), shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ],
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
