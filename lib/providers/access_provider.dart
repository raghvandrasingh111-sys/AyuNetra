import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessProvider with ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Doctor requests access for [patientId]. Upserts existing row (pending/denied -> pending).
  Future<bool> requestAccess({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client.from('doctor_patient_access').upsert(
        {
          'doctor_id': doctorId,
          'patient_id': patientId,
          'status': 'pending',
          'requested_at': DateTime.now().toIso8601String(),
          'responded_at': null,
        },
        onConflict: 'doctor_id,patient_id',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Doctor's view: all requests made by the doctor (pending/approved/denied).
  Future<List<Map<String, dynamic>>> fetchMyRequests(String doctorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final data = await _client
          .from('doctor_patient_access')
          .select('id, doctor_id, patient_id, status, requested_at, responded_at')
          .eq('doctor_id', doctorId)
          .order('requested_at', ascending: false);

      _isLoading = false;
      notifyListeners();
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return const [];
    }
  }

  /// Patient's inbox: requests from doctors.
  Future<List<Map<String, dynamic>>> fetchRequestsForPatient(String patientId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final data = await _client
          .from('doctor_patient_access')
          .select('id, doctor_id, patient_id, status, requested_at, responded_at')
          .eq('patient_id', patientId)
          .order('requested_at', ascending: false);

      _isLoading = false;
      notifyListeners();
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return const [];
    }
  }

  Future<bool> respondToRequest({
    required String requestId,
    required bool approve,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client.from('doctor_patient_access').update({
        'status': approve ? 'approved' : 'denied',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

