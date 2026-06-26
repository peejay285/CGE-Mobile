import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/profile.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/cge_button.dart';

const _premiumPriceNaira = 2000;
const _premiumPeriodDays = 30;

const _perks = [
  (
    LucideIcons.shieldCheck,
    'Verified profile review',
    'Submit your ID for manual verification — get a verified badge that appears on every listing.',
  ),
  (
    LucideIcons.image,
    'Higher listing limits',
    'More photos per listing, video listings, and a higher monthly listing cap.',
  ),
  (
    LucideIcons.sparkles,
    'Featured swap matches',
    'Your offered listings show up first when other users browse swap candidates.',
  ),
  (
    LucideIcons.trendingUp,
    'Priority placement',
    'Premium listings appear before free listings within a category and state filter.',
  ),
];

final _profileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  return AuthRepository().getProfile();
});

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() =>
      _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  bool _paying = false;

  Future<void> _pay(Profile profile) async {
    final user = SupabaseConfig.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with an email to upgrade')),
      );
      return;
    }
    setState(() => _paying = true);
    try {
      final checkoutUrl = await PaymentService.initializePremiumPayment();
      await PaymentService.openCheckout(checkoutUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paystack checkout opened. Premium activates after secure payment confirmation.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      ref.invalidate(_profileProvider);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('CGE Premium'),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sign in to upgrade'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (profile.isPremiumActive)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 18,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You're on Premium",
                              style: AppTypography.body.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Renews / expires '
                              '${DateTime.parse(profile.premiumExpiresAt!).toLocal().toString().split(' ').first}',
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.magenta.withValues(alpha: 0.1),
                      AppColors.cyan.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.magenta.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${_premiumPriceNaira.toStringAsFixed(0)}',
                          style: AppTypography.heading.copyWith(fontSize: 28),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ month',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One Paystack payment unlocks $_premiumPeriodDays days of Premium.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._perks.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(p.$1, size: 16, color: AppColors.cyan),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.$2,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.$3,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!profile.isPremiumActive)
                CgeButton(
                  label: _paying
                      ? 'Opening Paystack...'
                      : 'Upgrade with Paystack',
                  icon: LucideIcons.crown,
                  fullWidth: true,
                  isLoading: _paying,
                  onPressed: () => _pay(profile),
                ),
              const SizedBox(height: 8),
              Text(
                'One-time $_premiumPeriodDays-day pass. No auto-renew. Pay again from this page when it expires.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
