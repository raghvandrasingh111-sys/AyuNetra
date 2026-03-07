import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sanjeevni/providers/auth_provider.dart';
import 'package:sanjeevni/providers/access_provider.dart';
import 'package:sanjeevni/providers/prescription_provider.dart';
import 'package:sanjeevni/screens/splash_screen.dart';
import 'package:sanjeevni/utils/constants.dart';

TextTheme _safePoppinsTextTheme() {
  try {
    return GoogleFonts.poppinsTextTheme();
  } catch (_) {
    return ThemeData.light().textTheme;
  }
}

TextStyle _safePoppins(TextStyle? base, {double? fontSize, FontWeight? fontWeight, Color? color}) {
  try {
    return GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight, color: color);
  } catch (_) {
    return (base ?? const TextStyle()).copyWith(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey: Constants.supabaseAnonKey,
    );
  } catch (e) {
    // So app still loads on web if Supabase init fails (e.g. CORS, network)
    debugPrint('Supabase init failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccessProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
      ],
      child: MaterialApp(
        title: 'Sanjeevani',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Constants.primaryColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: _safePoppinsTextTheme(),
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Constants.primaryColor,
            foregroundColor: Colors.white,
            titleTextStyle: _safePoppins(null, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Constants.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: _safePoppins(null, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
