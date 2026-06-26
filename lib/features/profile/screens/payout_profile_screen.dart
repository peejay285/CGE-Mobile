import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/tournament_payout.dart';
import '../../../data/repositories/payout_profile_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';

final payoutProfileRepositoryProvider = Provider(
  (_) => PayoutProfileRepository(),
);

final payoutBanksProvider = FutureProvider.autoDispose<List<PaystackBank>>((
  ref,
) {
  return ref.read(payoutProfileRepositoryProvider).getBanks();
});

class PayoutProfileScreen extends ConsumerStatefulWidget {
  const PayoutProfileScreen({super.key});

  @override
  ConsumerState<PayoutProfileScreen> createState() =>
      _PayoutProfileScreenState();
}

class _PayoutProfileScreenState extends ConsumerState<PayoutProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  PaystackBank? _bank;
  bool _saving = false;

  @override
  void dispose() {
    _accountName.dispose();
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _bank == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(payoutProfileRepositoryProvider)
          .saveRecipient(
            accountName: _accountName.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            bankCode: _bank!.code,
            bankName: _bank!.name,
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout account verified and saved')),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save account: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final banks = ref.watch(payoutBanksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
        ),
        title: const Text('Prize Payout Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile?.payoutProfileVerifiedAt != null) ...[
            CgeCard(
              child: Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.payoutAccountName ?? 'Verified account',
                          style: AppTypography.label,
                        ),
                        Text(
                          '${profile?.payoutBankName ?? 'Bank'} •••• ${profile?.payoutAccountLast4 ?? ''}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Where should CGE send prizes?',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Paystack validates the recipient. CGE stores only the bank name, account name and final four digits in your profile.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _accountName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    prefixIcon: Icon(LucideIcons.user, size: 18),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter the account holder name'
                      : null,
                ),
                const SizedBox(height: 14),
                banks.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => CgeCard(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: AppColors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Could not load banks: $error')),
                        IconButton(
                          onPressed: () => ref.invalidate(payoutBanksProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                        ),
                      ],
                    ),
                  ),
                  data: (items) => DropdownButtonFormField<PaystackBank>(
                    initialValue: _bank,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                      prefixIcon: Icon(LucideIcons.landmark, size: 18),
                    ),
                    items: items
                        .map(
                          (bank) => DropdownMenuItem(
                            value: bank,
                            child: Text(
                              bank.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _bank = value),
                    validator: (value) =>
                        value == null ? 'Choose a bank' : null,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _accountNumber,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: '10-digit account number',
                    prefixIcon: Icon(LucideIcons.hash, size: 18),
                    counterText: '',
                  ),
                  validator: (value) =>
                      RegExp(r'^\d{10}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Enter a valid 10-digit account number',
                ),
                const SizedBox(height: 24),
                CgeButton(
                  label: profile?.payoutProfileVerifiedAt == null
                      ? 'Verify payout account'
                      : 'Replace payout account',
                  fullWidth: true,
                  isLoading: _saving,
                  onPressed: _save,
                  icon: LucideIcons.shieldCheck,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
