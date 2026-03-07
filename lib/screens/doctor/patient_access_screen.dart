import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        const SnackBar(content: Text('Enter patient Aadhar number')),
      );
      return;
    }

    final patientId = await rx.getPatientIdByAadhar(aadhar);
    if (patientId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patient found with this Aadhar.'),
          backgroundColor: Constants.errorColor,
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
        const SnackBar(content: Text('Access request sent. Waiting for patient approval.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(access.errorMessage ?? 'Failed to request access'),
          backgroundColor: Constants.errorColor,
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

    final approved = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'approved').toList();
    final pending = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'pending').toList();
    final denied = _myRequests.where((r) => (r['status']?.toString() ?? '') == 'denied').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Access'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Patient Aadhar Number',
                hintText: 'Enter 12-digit Aadhar',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _requestAccess,
                icon: const Icon(Icons.send),
                label: const Text('Request Access'),
              ),
            ),
            const SizedBox(height: 20),

            _SectionTitle(title: 'Approved', count: approved.length),
            const SizedBox(height: 8),
            ...approved.map((r) => _RequestTile(
                  status: 'approved',
                  patientId: r['patient_id']?.toString() ?? '',
                  requestedAt: r['requested_at']?.toString(),
                  onViewHistory: () => _viewHistory(r['patient_id']?.toString() ?? ''),
                )),
            if (approved.isEmpty) const _EmptyHint(text: 'No approved patients yet.'),

            const SizedBox(height: 16),
            _SectionTitle(title: 'Pending', count: pending.length),
            const SizedBox(height: 8),
            ...pending.map((r) => _RequestTile(
                  status: 'pending',
                  patientId: r['patient_id']?.toString() ?? '',
                  requestedAt: r['requested_at']?.toString(),
                )),
            if (pending.isEmpty) const _EmptyHint(text: 'No pending requests.'),

            const SizedBox(height: 16),
            _SectionTitle(title: 'Denied', count: denied.length),
            const SizedBox(height: 8),
            ...denied.map((r) => _RequestTile(
                  status: 'denied',
                  patientId: r['patient_id']?.toString() ?? '',
                  requestedAt: r['requested_at']?.toString(),
                )),
            if (denied.isEmpty) const _EmptyHint(text: 'No denied requests.'),
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
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Constants.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Constants.primaryColor),
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
    this.requestedAt,
    this.onViewHistory,
  });

  final String status;
  final String patientId;
  final String? requestedAt;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    Color c;
    IconData i;
    switch (status) {
      case 'approved':
        c = Constants.successColor;
        i = Icons.verified_outlined;
        break;
      case 'denied':
        c = Constants.errorColor;
        i = Icons.block;
        break;
      default:
        c = Constants.warningColor;
        i = Icons.hourglass_bottom;
    }

    return Card(
      child: ListTile(
        leading: Icon(i, color: c),
        title: Text('Patient: ${patientId.substring(0, patientId.length.clamp(0, 8))}...'),
        subtitle: Text('Status: $status${requestedAt == null ? '' : '\nRequested: $requestedAt'}'),
        isThreeLine: requestedAt != null,
        trailing: status == 'approved'
            ? TextButton(
                onPressed: onViewHistory,
                child: const Text('View'),
              )
            : null,
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}

