import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/access_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';
import 'patient_medical_history_screen.dart';

class PatientAccessScreen extends StatefulWidget {
  const PatientAccessScreen({super.key});

  @override
  State<PatientAccessScreen> createState() => _PatientAccessScreenState();
}

class _PatientAccessScreenState extends State<PatientAccessScreen> {
  final _aadharController = TextEditingController();
  List<Map<String, dynamic>> _myRequests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final access = context.read<AccessProvider>();
    final list = await access.fetchMyRequests(auth.currentUser!.id);
    if (!mounted) return;
    setState(() => _myRequests = list);
  }

  Future<void> _requestAccess() async {
    final auth = context.read<AuthProvider>();
    final access = context.read<AccessProvider>();
    final rx = context.read<PrescriptionProvider>();

    final aadhar = _aadharController.text.trim();
    if (aadhar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter patient Aadhar number', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final patientId = await rx.getPatientIdByAadhar(aadhar);
    if (patientId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No patient found with this Aadhar.', style: GoogleFonts.inter()),
          backgroundColor: Constants.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await access.requestAccess(
      doctorId: auth.currentUser!.id,
      patientId: patientId!,
    );

    if (!mounted) return;
    if (ok) {
      _aadharController.clear();
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access request sent. Waiting for patient approval.', style: GoogleFonts.inter()),
          backgroundColor: Constants.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(access.errorMessage ?? 'Failed to request access', style: GoogleFonts.inter()),
          backgroundColor: Constants.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewHistory(String patientId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientMedicalHistoryScreen(patientId: patientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessProvider>();
    final isLoading = access.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final approved = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'approved').toList();
    final pending = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'pending').toList();
    final denied = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'denied').toList();

    return Scaffold(
      backgroundColor: isDark ? Constants.backgroundDark : Constants.backgroundLight,
      appBar: AppBar(
        title: Text('Patient Access', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Constants.primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
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
                    'Request New Access',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _aadharController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Patient Aadhar Number',
                      hintText: 'Enter 12-digit Aadhar',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Constants.primaryColor),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _requestAccess,
                      icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        isLoading ? 'Requesting...' : 'Request Access',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (isLoading && _myRequests.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              _SectionTitle(title: 'Approved', count: approved.length),
              const SizedBox(height: 12),
              ...approved.map((r) => _RequestTile(
                    status: 'approved',
                    patientId: r['patient_id']?.toString() ?? '',
                    requestedAt: r['requested_at']?.toString(),
                    onViewHistory: () => _viewHistory(r['patient_id']?.toString() ?? ''),
                    isDark: isDark,
                  )),
              if (approved.isEmpty) const _EmptyHint(text: 'No approved patients yet.'),

              const SizedBox(height: 24),
              _SectionTitle(title: 'Pending', count: pending.length),
              const SizedBox(height: 12),
              ...pending.map((r) => _RequestTile(
                    status: 'pending',
                    patientId: r['patient_id']?.toString() ?? '',
                    requestedAt: r['requested_at']?.toString(),
                    isDark: isDark,
                  )),
              if (pending.isEmpty) const _EmptyHint(text: 'No pending requests.'),

              const SizedBox(height: 24),
              _SectionTitle(title: 'Denied', count: denied.length),
              const SizedBox(height: 12),
              ...denied.map((r) => _RequestTile(
                    status: 'denied',
                    patientId: r['patient_id']?.toString() ?? '',
                    requestedAt: r['requested_at']?.toString(),
                    isDark: isDark,
                  )),
              if (denied.isEmpty) const _EmptyHint(text: 'No denied requests.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Constants.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, 
              color: Constants.primaryColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.status,
    required this.patientId,
    required this.isDark,
    this.requestedAt,
    this.onViewHistory,
  });

  final String status;
  final String patientId;
  final bool isDark;
  final String? requestedAt;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    Color c;
    IconData i;
    Color bg;
    
    switch (status) {
      case 'approved':
        c = Constants.successColor;
        bg = c.withOpacity(0.1);
        i = Icons.verified_outlined;
        break;
      case 'denied':
        c = Constants.errorColor;
        bg = c.withOpacity(0.1);
        i = Icons.block;
        break;
      default:
        c = Constants.warningColor;
        bg = c.withOpacity(0.1);
        i = Icons.hourglass_bottom;
    }

    String formattedDate = '';
    if (requestedAt != null) {
      try {
        final dt = DateTime.parse(requestedAt!).toLocal();
        formattedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Constants.cardDark.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(i, color: c, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient ID: ${patientId.substring(0, patientId.length.clamp(0, 8))}...',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: c,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•  Requested: $formattedDate',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Constants.textMutedLight,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          if (status == 'approved')
            ElevatedButton(
              onPressed: onViewHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor.withOpacity(0.1),
                foregroundColor: Constants.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'View',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Constants.textMutedLight,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
