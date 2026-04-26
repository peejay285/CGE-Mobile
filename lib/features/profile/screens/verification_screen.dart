import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/profile.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_empty_state.dart';

const _idTypes = ["NIN slip", "Driver's licence", "Voter's card", "Passport"];

final _profileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  return AuthRepository().getProfile();
});

final _submissionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseConfig.currentUser;
  if (user == null) return [];
  final response = await SupabaseConfig.client
      .from('id_verification_submissions')
      .select()
      .eq('user_id', user.id)
      .order('submitted_at', ascending: false);
  return (response as List).cast<Map<String, dynamic>>();
});

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  XFile? _idFile;
  final List<XFile> _supportingFiles = [];
  bool _submitting = false;

  Future<void> _pickIdFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _idFile = picked);
  }

  Future<void> _addSupporting() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _supportingFiles.addAll(picked));
    }
  }

  Future<void> _submit() async {
    final user = SupabaseConfig.currentUser;
    if (user == null || _idFile == null) return;
    setState(() => _submitting = true);
    try {
      final folder = '${user.id}/${DateTime.now().millisecondsSinceEpoch}';
      final idExt = _idFile!.path.split('.').last;
      final idPath = '$folder/id.$idExt';
      final idBytes = await File(_idFile!.path).readAsBytes();
      await SupabaseConfig.client.storage
          .from('verification-docs')
          .uploadBinary(idPath, idBytes as dynamic);

      final supportingPaths = <String>[];
      for (var i = 0; i < _supportingFiles.length; i++) {
        final f = _supportingFiles[i];
        final ext = f.path.split('.').last;
        final p = '$folder/support_$i.$ext';
        final bytes = await File(f.path).readAsBytes();
        await SupabaseConfig.client.storage
            .from('verification-docs')
            .uploadBinary(p, bytes as dynamic);
        supportingPaths.add(p);
      }

      await SupabaseConfig.client.from('id_verification_submissions').insert({
        'user_id': user.id,
        'id_document_url': idPath,
        'supporting_doc_urls': supportingPaths,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted. We'll review within 48 hours.")),
      );
      setState(() {
        _idFile = null;
        _supportingFiles.clear();
      });
      ref.invalidate(_profileProvider);
      ref.invalidate(_submissionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);
    final submissionsAsync = ref.watch(_submissionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verified Profile'),
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (profile) {
          if (profile == null) {
            return const CgeEmptyState(
              icon: '🔒',
              title: 'Sign in to verify',
              subtitle: 'You need to be signed in.',
            );
          }
          final pending = (submissionsAsync.valueOrNull ?? [])
              .firstWhere((s) => s['status'] == 'pending',
                  orElse: () => <String, dynamic>{});
          final hasPending = pending.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(
                profile: profile,
                hasPending: hasPending,
              ),
              const SizedBox(height: 16),
              if (!profile.isPremiumActive)
                _PremiumGate()
              else if (!profile.isIdVerified && !hasPending)
                _SubmissionForm(
                  idFile: _idFile,
                  supportingFiles: _supportingFiles,
                  submitting: _submitting,
                  onPickId: _pickIdFile,
                  onAddSupporting: _addSupporting,
                  onClearId: () => setState(() => _idFile = null),
                  onRemoveSupporting: (i) =>
                      setState(() => _supportingFiles.removeAt(i)),
                  onSubmit: _submit,
                ),
              if ((submissionsAsync.valueOrNull ?? []).isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Submission history',
                    style: AppTypography.subheading.copyWith(fontSize: 12)),
                const SizedBox(height: 8),
                ...submissionsAsync.value!.map((s) => _HistoryRow(row: s)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Profile profile;
  final bool hasPending;
  const _StatusCard({required this.profile, required this.hasPending});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String title;
    String body;
    if (profile.isIdVerified) {
      color = AppColors.green;
      icon = LucideIcons.check;
      title = 'Your profile is verified';
      body = 'Your verified badge appears on listings, swap proposals, and your seller profile.';
    } else if (hasPending) {
      color = AppColors.gold;
      icon = LucideIcons.clock;
      title = 'Review pending';
      body = 'Your documents are with our team. We aim to decide within 48 hours.';
    } else if (!profile.isPremiumActive) {
      color = AppColors.magenta;
      icon = LucideIcons.shield;
      title = 'Verified profiles are a premium perk';
      body = 'Upgrade to Premium to unlock manual ID verification.';
    } else {
      color = AppColors.cyan;
      icon = LucideIcons.shield;
      title = 'Submit your ID to get verified';
      body = 'Upload a clear photo of your ID. A team member will review within 48 hours.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 4),
                Text(body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CgeButton(
      label: 'See Premium',
      icon: LucideIcons.crown,
      fullWidth: true,
      onPressed: () => context.push('/profile/upgrade'),
    );
  }
}

class _SubmissionForm extends StatelessWidget {
  final XFile? idFile;
  final List<XFile> supportingFiles;
  final bool submitting;
  final VoidCallback onPickId;
  final VoidCallback onAddSupporting;
  final VoidCallback onClearId;
  final void Function(int) onRemoveSupporting;
  final VoidCallback onSubmit;

  const _SubmissionForm({
    required this.idFile,
    required this.supportingFiles,
    required this.submitting,
    required this.onPickId,
    required this.onAddSupporting,
    required this.onClearId,
    required this.onRemoveSupporting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accepted ID types',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _idTypes
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.cyan, fontSize: 10)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          _FileSlot(
            label: 'ID document (required)',
            file: idFile,
            onPick: onPickId,
            onClear: onClearId,
          ),
          const SizedBox(height: 12),
          Text('Supporting documents (optional)',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (supportingFiles.isNotEmpty)
            ...supportingFiles.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.value.name,
                            style: AppTypography.bodySmall),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            size: 14, color: AppColors.textMuted),
                        onPressed: () => onRemoveSupporting(e.key),
                      ),
                    ],
                  ),
                )),
          OutlinedButton.icon(
            onPressed: onAddSupporting,
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add supporting document'),
          ),
          const SizedBox(height: 14),
          CgeButton(
            label: submitting ? 'Submitting...' : 'Submit for review',
            icon: LucideIcons.upload,
            fullWidth: true,
            isLoading: submitting,
            onPressed: idFile == null ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _FileSlot extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _FileSlot({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (file == null)
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(LucideIcons.upload, size: 14),
            label: const Text('Pick image'),
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(file!.name, style: AppTypography.bodySmall),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x,
                    size: 14, color: AppColors.textMuted),
                onPressed: onClear,
              ),
            ],
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _HistoryRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final status = row['status'] as String;
    final reason = row['rejection_reason'] as String?;
    Color color;
    IconData icon;
    if (status == 'approved') {
      color = AppColors.green;
      icon = LucideIcons.check;
    } else if (status == 'rejected') {
      color = AppColors.red;
      icon = LucideIcons.x;
    } else {
      color = AppColors.gold;
      icon = LucideIcons.clock;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status[0].toUpperCase() + status.substring(1),
                    style: AppTypography.body.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  DateTime.parse(row['submitted_at'] as String)
                      .toLocal()
                      .toString()
                      .split('.')
                      .first,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
                if (status == 'rejected' && reason != null) ...[
                  const SizedBox(height: 4),
                  Text('Reason: $reason',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.red, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
