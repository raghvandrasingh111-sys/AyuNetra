import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  static String _authErrorMessage(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('rate limit') || msg.contains('email rate limit')) {
      return 'Too many signup attempts. Please wait a few minutes and try again, or turn off "Confirm email" in Supabase Dashboard → Auth → Email.';
    }
    if (msg.contains('invalid') &&
        (msg.contains('credential') || msg.contains('password'))) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user not found') || msg.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('already registered') || msg.contains('email already')) {
      return 'This email is already registered. Try logging in.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }

  static String _signUpErrorMessage(String? msg) {
    if (msg == null || msg.isEmpty) return 'Sign up failed. Please try again.';
    final m = msg.toLowerCase();
    if (m.contains('rate limit') || m.contains('email rate limit')) {
      return 'Too many signup attempts. Wait a few minutes and try again. If you manage the server, turn off "Confirm email" in Supabase → Auth → Email to avoid this.';
    }
    return msg;
  }

  /// For patient: [loginId] is email. For doctor: [loginId] is doctor registration number.
  Future<bool> signIn(String loginId, String password, String userType) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final trimmed = loginId.trim();
      if (userType == 'doctor' && trimmed.contains('@')) {
        _errorMessage = 'Use your medical registration number to login, not an email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final email = userType == 'doctor'
          ? '$trimmed${Constants.doctorEmailSuffix}'
          : trimmed;

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = _client.auth.currentUser;
      if (user == null) {
        _errorMessage = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If no profile (e.g. trigger didn't run or old signup), create from user metadata
      if (profile == null) {
        final meta = user.userMetadata ?? {};
        final name = meta['name']?.toString() ?? 'User';
        final metaUserType = meta['user_type']?.toString() ?? 'patient';
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? email,
            'name': name,
            'user_type': metaUserType,
          }, onConflict: 'id');
          profile = await _client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();
        } catch (_) {
          _errorMessage = 'No profile found. Please sign up first.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (profile == null) {
          _errorMessage = 'No profile found. Please sign up first.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final profileUserType = profile['user_type']?.toString();
      if (profileUserType != userType) {
        _errorMessage =
            'Please select "${userType == 'patient' ? 'Patient' : 'Doctor'}" to match your account.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel(
        id: user.id,
        email: user.email ?? email,
        name: profile['name']?.toString() ?? 'User',
        userType: profileUserType!,
        phone: profile['phone']?.toString(),
        profileImageUrl: profile['profile_image_url']?.toString(),
        aadharNumber: profile['aadhar_number']?.toString(),
        doctorRegistrationNumber: profile['doctor_registration_number']?.toString(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = userType == 'doctor'
          ? _authMessageForDoctor(e.message)
          : _authMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _authErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  static String _authMessage(String? msg) {
    if (msg == null || msg.isEmpty) return 'Authentication failed.';
    final m = msg.toLowerCase();
    if (m.contains('rate limit') || m.contains('email rate limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (m.contains('invalid login') || m.contains('invalid_credentials')) {
      return 'Invalid email or password.';
    }
    if (m.contains('email not confirmed') || m.contains('confirm your email')) {
      return 'Please confirm your email using the link we sent you, then try again.';
    }
    return msg;
  }

  static String _authMessageForDoctor(String? msg) {
    if (msg == null || msg.isEmpty) return 'Authentication failed.';
    final m = msg.toLowerCase();
    if (m.contains('rate limit') || m.contains('email rate limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (m.contains('invalid login') || m.contains('invalid_credentials')) {
      return 'Invalid doctor registration number or password.';
    }
    if (m.contains('email not confirmed') || m.contains('confirm your email')) {
      return 'Please confirm your email, then try again.';
    }
    return msg;
  }

  /// Patient: [email], [password], [name], [aadharNumber]. [aadharNumber] must be unique.
  /// Doctor: [password], [name], [doctorRegistrationNumber]. Email is derived from registration number.
  Future<bool> signUp({
    required String password,
    required String name,
    required String userType,
    String? email,
    String? aadharNumber,
    String? doctorRegistrationNumber,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (userType == 'patient') {
        if (email == null || email.trim().isEmpty) {
          _errorMessage = 'Please enter your email.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final aadhar = _normalizeAadhar(aadharNumber);
        if (aadhar == null || aadhar.length != 12) {
          _errorMessage = 'Please enter a valid 12-digit Aadhar number.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        // Check Aadhar uniqueness
        final existing = await _client
            .from('profiles')
            .select('id')
            .eq('aadhar_number', aadhar)
            .maybeSingle();
        if (existing != null) {
          _errorMessage = 'This Aadhar number is already registered.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final response = await _client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'name': name.trim(), 'user_type': userType},
        );

        if (response.session == null) {
          _isLoading = false;
          notifyListeners();
          return true;
        }

        final user = response.user;
        if (user == null) {
          _errorMessage = 'Sign up failed. Try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': email.trim(),
            'name': name.trim(),
            'user_type': userType,
            'aadhar_number': aadhar,
          }, onConflict: 'id');
        } catch (_) {}

        _currentUser = UserModel(
          id: user.id,
          email: user.email ?? email.trim(),
          name: name.trim(),
          userType: userType,
          aadharNumber: aadhar,
        );
      } else {
        // Doctor: registration number must not contain @ (we append @ayunetra.doctor)
        final regNo = (doctorRegistrationNumber ?? '').trim();
        if (regNo.isEmpty) {
          _errorMessage = 'Please enter your doctor registration number.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (regNo.contains('@')) {
          _errorMessage = 'Use your medical registration ID only, not an email address.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final doctorEmail = '$regNo${Constants.doctorEmailSuffix}';

        final response = await _client.auth.signUp(
          email: doctorEmail,
          password: password,
          data: {'name': name.trim(), 'user_type': userType},
        );

        if (response.session == null) {
          _isLoading = false;
          notifyListeners();
          return true;
        }

        final user = response.user;
        if (user == null) {
          _errorMessage = 'Sign up failed. Try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': doctorEmail,
            'name': name.trim(),
            'user_type': userType,
            'doctor_registration_number': regNo,
          }, onConflict: 'id');
        } catch (_) {}

        _currentUser = UserModel(
          id: user.id,
          email: doctorEmail,
          name: name.trim(),
          userType: userType,
          doctorRegistrationNumber: regNo,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _signUpErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _authErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  static String? _normalizeAadhar(String? value) {
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 ? digits : null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return;

      _currentUser = UserModel(
        id: user.id,
        email: user.email ?? '',
        name: profile['name']?.toString() ?? 'User',
        userType: profile['user_type']?.toString() ?? 'patient',
        phone: profile['phone']?.toString(),
        profileImageUrl: profile['profile_image_url']?.toString(),
        aadharNumber: profile['aadhar_number']?.toString(),
        doctorRegistrationNumber: profile['doctor_registration_number']?.toString(),
      );
      notifyListeners();
    } catch (_) {
      _currentUser = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch profile by ID. Doctors can fetch patient profiles; users can fetch own.
  Future<UserModel?> getProfileById(String id) async {
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (profile == null) return null;

      return UserModel(
        id: profile['id']?.toString() ?? id,
        email: profile['email']?.toString() ?? '',
        name: profile['name']?.toString() ?? 'User',
        userType: profile['user_type']?.toString() ?? 'patient',
        phone: profile['phone']?.toString(),
        profileImageUrl: profile['profile_image_url']?.toString(),
        aadharNumber: profile['aadhar_number']?.toString(),
        doctorRegistrationNumber: profile['doctor_registration_number']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
