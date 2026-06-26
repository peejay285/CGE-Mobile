import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../providers/events_provider.dart';
import '../../../data/models/event.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isRegistered = false;
  bool _isRegistering = false;

  int get _eventIdInt => int.parse(widget.eventId);

  BadgeColor _typeBadgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'party':
        return BadgeColor.magenta;
      case 'special':
        return BadgeColor.gold;
      case 'demo':
        return BadgeColor.cyan;
      case 'package':
        return BadgeColor.green;
      default:
        return BadgeColor.cyan;
    }
  }

  String _formatPrice(int price) {
    return '\u20A6${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _handleRegister() async {
    setState(() => _isRegistering = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.register(_eventIdInt);
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isRegistering = false;
        });
        ref.invalidate(eventDetailProvider(_eventIdInt));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnregister() async {
    setState(() => _isRegistering = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.unregister(_eventIdInt);
      if (mounted) {
        setState(() {
          _isRegistered = false;
          _isRegistering = false;
        });
        ref.invalidate(eventDetailProvider(_eventIdInt));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unregister: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(_eventIdInt));

    return Scaffold(
      body: eventAsync.when(
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(error.toString()),
        data: (event) {
          if (event == null) {
            return _buildError('Event not found');
          }
          // Sync registration state from server on first load
          if (event.userRegistered == true && !_isRegistered && !_isRegistering) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isRegistered) {
                setState(() => _isRegistered = true);
              }
            });
          }
          return _buildContent(event);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CgeSkeleton(height: 220, borderRadius: 16),
                const SizedBox(height: 16),
                const CgeSkeleton.text(width: 100),
                const SizedBox(height: 12),
                const CgeSkeleton.text(width: 240),
                const SizedBox(height: 12),
                const CgeSkeleton.text(width: 180),
                const SizedBox(height: 20),
                const CgeSkeleton(height: 80),
                const SizedBox(height: 20),
                const CgeSkeleton(height: 48, borderRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.red),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          CgeButton(
            label: 'Go Back',
            onPressed: () => context.pop(),
            variant: CgeButtonVariant.secondary,
            icon: LucideIcons.arrowLeft,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Event event) {
    final registered = event.registeredCount ?? 0;
    final capacity = event.capacity ?? 0;
    final isFull = capacity > 0 && registered >= capacity;
    final capacityRatio = capacity > 0 ? registered / capacity : 0.0;
    final price = event.price ?? 0;
    final description = event.description ?? '';

    return CustomScrollView(
      slivers: [
        // Hero image area
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.base.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 20),
              ),
            ),
          ),
          title: Text(
            event.title,
            style: AppTypography.label.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImagePlaceholder(event.type),
                  )
                : _buildImagePlaceholder(event.type),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                CgeBadge(
                  label: event.type[0].toUpperCase() + event.type.substring(1),
                  color: _typeBadgeColor(event.type),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  event.title,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 16),

                // Date and time row
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      event.date,
                      style: AppTypography.body.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 20),
                    Icon(LucideIcons.clock, size: 16, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: AppTypography.body.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                Text('About', style: AppTypography.subheading),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Price
                CgeCard(
                  child: Row(
                    children: [
                      Icon(LucideIcons.banknote, size: 20, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Text('Price', style: AppTypography.subheading),
                      const Spacer(),
                      if (price > 0)
                        Text(
                          _formatPrice(price),
                          style: AppTypography.monoLarge.copyWith(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const CgeBadge(
                          label: 'FREE',
                          color: BadgeColor.green,
                          fontSize: 14,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Capacity section
                CgeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.users, size: 18, color: AppColors.cyan),
                          const SizedBox(width: 8),
                          Text('Capacity', style: AppTypography.subheading),
                          const Spacer(),
                          Text(
                            '$registered/$capacity spots filled',
                            style: AppTypography.label.copyWith(
                              color: isFull ? AppColors.red : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: capacityRatio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull ? AppColors.red : AppColors.cyan,
                          ),
                        ),
                      ),
                      if (isFull) ...[
                        const SizedBox(height: 8),
                        Text(
                          'This event is fully booked',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Register / Unregister buttons
                if (_isRegistered) ...[
                  // Registered state
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle, size: 18, color: AppColors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Registered \u2713',
                          style: AppTypography.label.copyWith(
                            color: AppColors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CgeButton(
                    label: 'Unregister',
                    onPressed: _isRegistering ? null : _handleUnregister,
                    isLoading: _isRegistering,
                    variant: CgeButtonVariant.secondary,
                    fullWidth: true,
                    icon: LucideIcons.x,
                  ),
                ] else if (isFull) ...[
                  CgeButton(
                    label: 'Sold Out',
                    onPressed: null,
                    fullWidth: true,
                    variant: CgeButtonVariant.secondary,
                  ),
                ] else ...[
                  CgeButton(
                    label: 'Register Now',
                    onPressed: _isRegistering ? null : _handleRegister,
                    isLoading: _isRegistering,
                    fullWidth: true,
                    icon: LucideIcons.ticket,
                  ),
                ],

                // Bottom spacing
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String type) {
    final color = switch (type.toLowerCase()) {
      'party' => AppColors.magenta,
      'special' => AppColors.gold,
      'demo' => AppColors.cyan,
      'package' => AppColors.green,
      _ => AppColors.cyan,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.3),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarDays, size: 48, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            type[0].toUpperCase() + type.substring(1),
            style: AppTypography.label.copyWith(
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
