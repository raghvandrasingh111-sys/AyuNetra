import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/access_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class DoctorAccessRequestsView extends StatefulWidget {
  const DoctorAccessRequestsView({super.key});

  @override
  State<DoctorAccessRequestsView> createState() => _DoctorAccessRequestsViewState();
}

class _DoctorAccessRequestsViewState extends State<DoctorAccessRequestsView> {
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final access = context.read<AccessProvider>();
    final list = await access.fetchRequestsForPatient(auth.currentUser!.id);
    if (!mounted) return;
    setState(() => _requests = list);
  }

  Future<void> _respond(String requestId, bool approve) async {
    final access = context.read<AccessProvider>();
    final ok = await access.respondToRequest(requestId: requestId, approve: approve);
    if (!mounted) return;
    if (ok) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Approved access.' : 'Denied access.'),
          backgroundColor: approve ? Constants.successColor : Constants.errorColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(access.errorMessage ?? 'Failed to update request'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessProvider>();
    final pending = _requests.where((r) => (r['status']?.toString() ?? '') == 'pending').toList();
    final approved = _requests.where((r) => (r['status']?.toString() ?? '') == 'approved').toList();
    final denied = _requests.where((r) => (r['status']?.toString() ?? '') == 'denied').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Doctor Access Requests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Approve a doctor to let them view your medical history.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Constants.textMutedDark : Constants.textMutedLight,
                ),
          ),
          const SizedBox(height: 16),
          if (access.isLoading) const LinearProgressIndicator(),

          _section(context, title: 'Pending', count: pending.length),
          const SizedBox(height: 8),
          ...pending.map((r) => _RequestCard(
                status: 'pending',
                doctorId: r['doctor_id']?.toString() ?? '',
                requestedAt: r['requested_at']?.toString(),
                onApprove: () => _respond(r['id']?.toString() ?? '', true),
                onDeny: () => _respond(r['id']?.toString() ?? '', false),
              )),
          if (pending.isEmpty) const _Empty(text: 'No pending requests.'),

          const SizedBox(height: 18),
          _section(context, title: 'Approved', count: approved.length),
          const SizedBox(height: 8),
          ...approved.map((r) => _RequestCard(
                status: 'approved',
                doctorId: r['doctor_id']?.toString() ?? '',
                requestedAt: r['requested_at']?.toString(),
              )),
          if (approved.isEmpty) const _Empty(text: 'No approved doctors.'),

          const SizedBox(height: 18),
          _section(context, title: 'Denied', count: denied.length),
          const SizedBox(height: 8),
          ...denied.map((r) => _RequestCard(
                status: 'denied',
                doctorId: r['doctor_id']?.toString() ?? '',
                requestedAt: r['requested_at']?.toString(),
              )),
          if (denied.isEmpty) const _Empty(text: 'No denied requests.'),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required int count}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.status,
    required this.doctorId,
    this.requestedAt,
    this.onApprove,
    this.onDeny,
  });

  final String status;
  final String doctorId;
  final String? requestedAt;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(i, color: c),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Doctor: ${doctorId.substring(0, doctorId.length.clamp(0, 10))}...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 11),
                  ),
                ),
              ],
            ),
            if (requestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Requested: $requestedAt',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDeny,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Constants.errorColor,
                        side: const BorderSide(color: Constants.errorColor),
                      ),
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.successColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: TextStyle(color: Colors.grey[600])),
    );
  }
}

