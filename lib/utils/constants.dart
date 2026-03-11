import 'package:flutter/material.dart';

class Constants {
  // Supabase - Replace with your project URL and anon key from Supabase dashboard
  static const String supabaseUrl = 'https://qqmnyvdkbblekwvibaqp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxbW55dmRrYmJsZWt3dmliYXFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MDg0MzEsImV4cCI6MjA4ODM4NDQzMX0.wxTOOavT5zhjH3Tl_J-gMqrjl3Y9kjFqp8VWyyLYShI';
  // static const String supabaseUrl = 'https://xjixpmxichjrlagwomev.supabase.co';
  // static const String supabaseAnonKey =
  //     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqaXhwbXhpY2hqcmxhZ3dvbWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MDU0NTcsImV4cCI6MjA4NTA4MTQ1N30.KJ7BWOvWv_w1RUbpqeiGmre41D8777bKdCL2lzapGLo';

  /// Used for doctor login: email = registrationNumber + this suffix
  static const String doctorEmailSuffix = '@ayunetra.doctor';

  // Google Generative AI - Replace with your key from https://aistudio.google.com/apikey
  static const String geminiApiKey = 'AIzaSyCqdN8icLylFqalaZWWJvTlry6NhE2oUGQ';

  // App Colors (Figma / AyuNetra design)
  static const Color primaryColor = Color(0xFF13EC92);
  static const Color secondaryColor = Color(0xFF13EC92);
  static const Color accentColor = Color(0xFF13EC92);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Figma design system
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color backgroundDark = Color(0xFF10221A);
  static const Color cardDark = Color(0xFF1A3328);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textMutedDark = Color(0xFF92C9B2);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF13EC92), Color(0xFF0FBF75)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
}
