import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/payment_service.dart';
import '../../../data/models/marketplace_listing.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/swap_state_tracker.dart';

final _outgoingProposalsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  return ref.read(marketplaceRepositoryProvider).getMyOutgoingProposals();
});

final _incomingProposalsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  return ref.read(marketplaceRepositoryProvider).getMyIncomingProposals();
});

class SwapProposalsScreen extends ConsumerStatefulWidget {
  const SwapProposalsScreen({super.key});

  @override
  ConsumerState<SwapProposalsScreen> createState() =>
      _SwapProposalsScreenState();
}

class _SwapProposalsScreenState extends ConsumerState<SwapProposalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Swap Proposals'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.magenta,
          labelColor: AppColors.text,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Outgoing'),
            Tab(text: 'Incoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProposalList(side: 'proposer'),
          _ProposalList(side: 'owner'),
        ],
      ),
    );
  }
}

class _ProposalList extends ConsumerWidget {
  final String side; // 'proposer' | 'owner'

  const _ProposalList({required this.side});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOutgoing = side == 'proposer';
    final async = ref.watch(
      isOutgoing ? _outgoingProposalsProvider : _incomingProposalsProvider,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          isOutgoing ? _outgoingProposalsProvider : _incomingProposalsProvider,
        );
      },
      color: AppColors.cyan,
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load: $e',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                CgeEmptyState(
                  icon: '🔁',
                  title: isOutgoing
                      ? 'No outgoing proposals'
                      : 'No incoming proposals',
                  subtitle: isOutgoing
                      ? "You haven't proposed any swaps yet."
                      : 'Nobody has proposed a swap on your listings yet.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final raw = rows[i] as Map<String, dynamic>;
              final proposal = SwapProposal.fromJson(raw);
              return _ProposalCard(
                proposal: proposal,
                raw: raw,
                side: side,
                onChanged: () => ref.invalidate(
                  isOutgoing
                      ? _outgoingProposalsProvider
                      : _incomingProposalsProvider,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProposalCard extends ConsumerStatefulWidget {
  final SwapProposal proposal;
  final Map<String, dynamic> raw;
  final String side; // 'proposer' | 'owner'
  final VoidCallback onChanged;

  const _ProposalCard({
    required this.proposal,
    required this.raw,
    required this.side,
    required this.onChanged,
  });

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _busy = false;
  String _open = ''; // '' | 'tracking' | 'cancel' | 'dispute'
  final _trackingCtl = TextEditingController();
  final _reasonCtl = TextEditingController();

  @override
  void dispose() {
    _trackingCtl.dispose();
    _reasonCtl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _open = '';
          _trackingCtl.clear();
          _reasonCtl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proposal;
    final isOutgoing = widget.side == 'proposer';
    final isPending = p.status == 'pending';
    final isActive = p.status == 'accepted' || p.status == 'in_transit';
    final mySideShipped = isOutgoing
        ? p.proposerShippedAt != null
        : p.ownerShippedAt != null;
    final theirSideShipped = isOutgoing
        ? p.ownerShippedAt != null
        : p.proposerShippedAt != null;
    final mySideReceived = isOutgoing
        ? p.proposerReceivedAt != null
        : p.ownerReceivedAt != null;

    final repo = ref.read(marketplaceRepositoryProvider);
    final offered = widget.raw['offered_listing'] as Map<String, dynamic>?;
    final target = widget.raw['target_listing'] as Map<String, dynamic>?;
    final proposer = widget.raw['proposer'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — show the pair of items being swapped
          Row(
            children: [
              Expanded(
                child: _MiniListing(
                  label: isOutgoing ? 'You offered' : 'They offered',
                  raw: offered,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.repeat,
                  size: 14,
                  color: AppColors.magenta,
                ),
              ),
              Expanded(
                child: _MiniListing(
                  label: isOutgoing ? 'You want' : 'Your listing',
                  raw: target,
                ),
              ),
            ],
          ),

          if (!isOutgoing && proposer != null) ...[
            const SizedBox(height: 8),
            Text(
              'From @${proposer['gamertag'] ?? proposer['full_name'] ?? 'CGE Member'}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],

          if (p.message != null && p.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${p.message!}"',
              style: AppTypography.body.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 10),
          SwapStateTracker(proposal: p),

          if (isActive) ...[
            const SizedBox(height: 10),
            _buildAssistPanel(p, repo),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                p.createdAt.split('T').first,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              CgeBadge(label: p.status, color: _statusColor(p.status)),
            ],
          ),

          // Owner-side: pending → accept/decline
          if (!isOutgoing && isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CgeButton(
                    label: 'Accept',
                    icon: LucideIcons.check,
                    isLoading: _busy,
                    variant: CgeButtonVariant.primary,
                    onPressed: () => _run(
                      () => repo.acceptSwapProposal(p.id),
                      'Proposal accepted',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CgeButton(
                    label: 'Decline',
                    icon: LucideIcons.x,
                    isLoading: _busy,
                    variant: CgeButtonVariant.danger,
                    onPressed: () => _run(
                      () => repo.declineSwapProposal(p.id),
                      'Proposal declined',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Active state — ship/receive controls
          if (isActive) ...[
            const SizedBox(height: 10),
            if (!mySideShipped && _open != 'tracking')
              CgeButton(
                label: 'Mark my item as shipped',
                icon: LucideIcons.truck,
                fullWidth: true,
                isLoading: _busy,
                onPressed: () => setState(() => _open = 'tracking'),
              ),
            if (_open == 'tracking') ...[
              TextField(
                controller: _trackingCtl,
                decoration: InputDecoration(
                  hintText: 'Tracking number (optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CgeButton(
                      label: 'Confirm shipped',
                      isLoading: _busy,
                      onPressed: () => _run(
                        () => repo.markSwapShipped(
                          proposalId: p.id,
                          side: widget.side,
                          tracking: _trackingCtl.text.trim().isEmpty
                              ? null
                              : _trackingCtl.text.trim(),
                        ),
                        'Marked as shipped',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CgeButton(
                    label: 'Back',
                    variant: CgeButtonVariant.ghost,
                    onPressed: () => setState(() => _open = ''),
                  ),
                ],
              ),
            ],
            if (theirSideShipped && !mySideReceived && _open == '') ...[
              const SizedBox(height: 8),
              CgeButton(
                label: 'Mark their item as received',
                icon: LucideIcons.package,
                fullWidth: true,
                isLoading: _busy,
                onPressed: () => _run(
                  () => repo.markSwapReceived(
                    proposalId: p.id,
                    side: widget.side,
                  ),
                  'Receipt confirmed',
                ),
              ),
            ],

            if (_open == '' || _open == 'cancel' || _open == 'dispute') ...[
              const SizedBox(height: 10),
              if (_open == '')
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _open = 'cancel'),
                      child: Text(
                        'Cancel swap',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => setState(() => _open = 'dispute'),
                      child: Text(
                        'Report a problem',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              if (_open == 'cancel' || _open == 'dispute') ...[
                Text(
                  _open == 'cancel'
                      ? 'Why are you cancelling?'
                      : "What's the problem?",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtl,
                  decoration: InputDecoration(
                    hintText: 'A short reason',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CgeButton(
                        label: _open == 'cancel' ? 'Cancel swap' : 'Report',
                        isLoading: _busy,
                        variant: _open == 'cancel'
                            ? CgeButtonVariant.danger
                            : CgeButtonVariant.primary,
                        onPressed: _reasonCtl.text.trim().isEmpty
                            ? null
                            : () => _run(
                                () => _open == 'cancel'
                                    ? repo.cancelSwap(
                                        proposalId: p.id,
                                        reason: _reasonCtl.text.trim(),
                                      )
                                    : repo.disputeSwap(
                                        proposalId: p.id,
                                        reason: _reasonCtl.text.trim(),
                                      ),
                                _open == 'cancel'
                                    ? 'Swap cancelled'
                                    : 'Reported',
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CgeButton(
                      label: 'Back',
                      variant: CgeButtonVariant.ghost,
                      onPressed: () => setState(() => _open = ''),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAssistPanel(SwapProposal proposal, dynamic repo) {
    final status = proposal.assistStatus ?? 'none';
    final userId = SupabaseConfig.currentUser?.id;
    SwapAssistPayment? myPayment;
    for (final payment in proposal.assistPayments) {
      if (payment.payerId == userId) {
        myPayment = payment;
        break;
      }
    }
    final pendingPayment = myPayment?.paymentStatus == 'pending'
        ? myPayment
        : null;

    if (status == 'none') {
      return CgeButton(
        label: 'Request CGE-Assisted Swap',
        icon: LucideIcons.shieldCheck,
        variant: CgeButtonVariant.secondary,
        fullWidth: true,
        isLoading: _busy,
        onPressed: () => _run(
          () => repo.requestSwapAssistance(proposal.id),
          'CGE assistance requested',
        ),
      );
    }

    if (status == 'awaiting_payment') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CGE assistance awaiting payment', style: AppTypography.label),
            const SizedBox(height: 4),
            Text(
              'Each party settles their share before CGE facilitation activates.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (pendingPayment != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CgeButton(
                      label: 'Pay ₦${pendingPayment.total}',
                      isLoading: _busy,
                      onPressed: () => _run(() async {
                        final url =
                            await PaymentService.initializeRecordPayment(
                              type: 'swap_assist',
                              recordId: pendingPayment.id,
                              metadata: {
                                'assist_payment_id': pendingPayment.id,
                              },
                            );
                        await PaymentService.openCheckout(url);
                      }, 'Paystack checkout opened'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CgeButton(
                      label: 'Use Premium',
                      variant: CgeButtonVariant.secondary,
                      isLoading: _busy,
                      onPressed: () => _run(
                        () => repo.coverSwapAssistWithPremium(proposal.id),
                        'Premium credit applied',
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const CgeBadge(
                label: 'Your share is settled',
                color: BadgeColor.green,
              ),
            ],
          ],
        ),
      );
    }

    if (status == 'active') {
      return const CgeBadge(
        label: 'CGE assistance active',
        color: BadgeColor.green,
      );
    }

    if (status == 'completed') {
      return const CgeBadge(
        label: 'CGE-assisted swap completed',
        color: BadgeColor.cyan,
      );
    }

    return CgeBadge(label: 'Assistance $status', color: BadgeColor.gold);
  }
}

BadgeColor _statusColor(String s) {
  switch (s) {
    case 'completed':
      return BadgeColor.green;
    case 'accepted':
    case 'in_transit':
      return BadgeColor.cyan;
    case 'declined':
    case 'cancelled':
    case 'expired':
      return BadgeColor.red;
    case 'disputed':
      return BadgeColor.gold;
    default:
      return BadgeColor.gold;
  }
}

class _MiniListing extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? raw;

  const _MiniListing({required this.label, required this.raw});

  @override
  Widget build(BuildContext context) {
    final title = (raw?['title'] as String?) ?? 'Unknown item';
    final images = (raw?['images'] as List?)?.cast<String>();
    final firstImage = images?.isNotEmpty == true ? images!.first : null;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: firstImage != null
              ? Image.network(
                  firstImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    LucideIcons.package,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                )
              : const Icon(
                  LucideIcons.package,
                  size: 16,
                  color: AppColors.textMuted,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
