import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/pricing.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_skeleton.dart';
import '../../../widgets/cge_empty_state.dart';
import '../../../widgets/cge_button.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  static String _zoneName(String zoneId) {
    switch (zoneId) {
      case 'main':
        return 'Main Lounge';
      case 'vip':
        return 'VIP Lounge';
      case 'vr':
        return 'VR Zone';
      default:
        return zoneId;
    }
  }

  static BadgeColor _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return BadgeColor.green;
      case 'cancelled':
        return BadgeColor.red;
      case 'completed':
        return BadgeColor.cyan;
      default:
        return BadgeColor.cyan;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CgeSkeleton(height: 140, borderRadius: 16),
              ),
            ),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text('Failed to load bookings',
                  style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text('$error',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CgeButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(userBookingsProvider),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return CgeEmptyState(
              icon: '\u{1F4C5}',
              title: 'No bookings yet',
              subtitle: 'Book your first gaming session!',
              actionLabel: 'Book Now',
              onAction: () => context.push('/lounge'),
            );
          }

          return RefreshIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(userBookingsProvider);
              // Wait for the provider to reload
              await ref.read(userBookingsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingCard(
                  booking: booking,
                  onTap: () => _showBookingDetail(context, ref, booking),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showBookingDetail(
      BuildContext context, WidgetRef ref, Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Text('Booking Details',
                        style: AppTypography.headingSmall),
                  ),
                  CgeBadge(
                    label: booking.status.toUpperCase(),
                    color: _statusColor(booking.status),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _DetailRow(
                icon: LucideIcons.mapPin,
                label: 'Zone',
                value: _zoneName(booking.zoneId),
              ),
              _DetailRow(
                icon: LucideIcons.gamepad2,
                label: 'Game',
                value: booking.gameName,
              ),
              _DetailRow(
                icon: LucideIcons.calendar,
                label: 'Date',
                value: booking.bookingDate,
              ),
              _DetailRow(
                icon: LucideIcons.clock,
                label: 'Time',
                value: booking.timeSlot,
              ),
              _DetailRow(
                icon: LucideIcons.timer,
                label: 'Duration',
                value:
                    '${booking.duration} ${booking.duration == 1 ? 'hour' : 'hours'}',
              ),

              if (booking.drinks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Drinks & Add-ons',
                    style: AppTypography.subheading.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                ...booking.drinks.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.coffee,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text('${e.key} x${e.value}',
                            style: AppTypography.body),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Session', style: AppTypography.body),
                  Text(Pricing.formatPrice(booking.sessionTotal),
                      style: AppTypography.mono),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add-ons', style: AppTypography.body),
                  Text(Pricing.formatPrice(booking.drinksTotal),
                      style: AppTypography.mono),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: AppTypography.subheading.copyWith(fontSize: 16)),
                  Text(Pricing.formatPrice(booking.total),
                      style: AppTypography.monoLarge),
                ],
              ),

              const SizedBox(height: 12),

              _DetailRow(
                icon: LucideIcons.creditCard,
                label: 'Payment',
                value:
                    '${booking.paymentMethod == 'venue' ? 'Pay at Venue' : 'Paystack'} (${booking.paymentStatus})',
              ),

              if (booking.passCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('Passcode',
                          style: AppTypography.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        booking.passCode!,
                        style: AppTypography.mono.copyWith(
                          fontSize: 28,
                          color: AppColors.cyan,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Show this at the venue',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],

              if (booking.status == 'confirmed') ...[
                const SizedBox(height: 24),
                CgeButton(
                  label: 'Cancel Booking',
                  variant: CgeButtonVariant.danger,
                  fullWidth: true,
                  icon: LucideIcons.x,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text('Cancel Booking?',
                            style: AppTypography.subheading),
                        content: Text(
                            'This action cannot be undone.',
                            style: AppTypography.body),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cancel Booking',
                                style: TextStyle(color: AppColors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await BookingRepository()
                            .cancelBooking(booking.id);
                        ref.invalidate(userBookingsProvider);
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking cancelled'),
                              backgroundColor: AppColors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to cancel: $e'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: zone + status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.gamepad2,
                    size: 18, color: AppColors.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyBookingsScreen._zoneName(booking.zoneId),
                      style: AppTypography.subheading.copyWith(fontSize: 14),
                    ),
                    Text(
                      booking.gameName,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              CgeBadge(
                label: booking.status.toUpperCase(),
                color: MyBookingsScreen._statusColor(booking.status),
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date, time, duration row
          Row(
            children: [
              const Icon(LucideIcons.calendar,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(booking.bookingDate, style: AppTypography.bodySmall),
              const SizedBox(width: 16),
              const Icon(LucideIcons.clock,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(booking.timeSlot, style: AppTypography.bodySmall),
              const SizedBox(width: 16),
              const Icon(LucideIcons.timer,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('${booking.duration}h', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 12),

          // Price + passcode row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Pricing.formatPrice(booking.total),
                style: AppTypography.monoLarge.copyWith(fontSize: 16),
              ),
              if (booking.passCode != null)
                Row(
                  children: [
                    const Icon(LucideIcons.key,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      booking.passCode!,
                      style: AppTypography.mono.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.body.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
