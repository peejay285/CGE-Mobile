import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/pricing.dart';
import '../../../core/services/payment_service.dart';
import '../../../data/remote/supabase_config.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0; // 0=zone, 1=game/schedule, 2=drinks, 3=payment
  String? _selectedZone;
  String? _selectedGame;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  int _duration = 1;
  final Map<String, int> _addOns = {};
  String _paymentMethod = 'paystack'; // 'paystack' or 'venue'
  bool _isProcessing = false;

  List<String> get _gamesForZone {
    switch (_selectedZone) {
      case 'main':
        return AppConstants.mainLoungeGames;
      case 'vip':
        return AppConstants.vipLoungeGames;
      case 'vr':
        return AppConstants.vrGames;
      default:
        return [];
    }
  }

  int get _sessionTotal => _selectedZone != null && _selectedGame != null
      ? Pricing.getSessionTotal(
          zoneId: _selectedZone!,
          game: _selectedGame!,
          duration: _duration,
        )
      : 0;

  int get _addOnsTotal => Pricing.getAddOnsTotal(_addOns);
  int get _grandTotal => _sessionTotal + _addOnsTotal;

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedZone != null;
      case 1:
        return _selectedGame != null && _selectedTimeSlot != null;
      case 2:
        return true; // add-ons are optional
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        _showError('Please sign in to book a session');
        return;
      }

      final repo = ref.read(bookingRepositoryProvider);
      final bookingDate =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final availability = await repo.checkAvailability(
        zoneId: _selectedZone!,
        date: bookingDate,
        timeSlot: _selectedTimeSlot!,
        duration: _duration,
      );
      if (!availability.available) {
        _showError('That time is now full. Please choose another slot.');
        return;
      }

      // The server recalculates totals and creates the booking atomically.
      final booking = await repo.createBooking(
        zoneId: _selectedZone!,
        gameName: _selectedGame!,
        bookingDate: bookingDate,
        timeSlot: _selectedTimeSlot!,
        duration: _duration,
        drinks: _addOns,
        sessionTotal: _sessionTotal,
        drinksTotal: _addOnsTotal,
        total: _grandTotal,
        paymentMethod: _paymentMethod,
      );

      if (_paymentMethod == 'paystack' &&
          booking.paymentStatus != 'paid' &&
          booking.total > 0) {
        final checkoutUrl = await PaymentService.initializeRecordPayment(
          type: 'booking',
          recordId: booking.id,
          metadata: {
            'booking_id': booking.id,
            'zone': booking.zoneId,
            'game': booking.gameName,
          },
        );
        await PaymentService.openCheckout(checkoutUrl);
      }

      if (!mounted) return;

      final awaitingPayment =
          _paymentMethod == 'paystack' && booking.paymentStatus != 'paid';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(
                awaitingPayment
                    ? LucideIcons.externalLink
                    : LucideIcons.checkCircle2,
                color: awaitingPayment ? AppColors.gold : AppColors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  awaitingPayment ? 'Complete Payment' : 'Booking Confirmed!',
                  style: AppTypography.subheading,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (awaitingPayment) ...[
                Text(
                  'Paystack checkout opened in your browser. Your booking will be marked paid after the secure webhook confirms it.',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text('Your passcode:', style: AppTypography.body),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cyan),
                  ),
                  child: Text(
                    booking.passCode ?? 'PENDING',
                    style: AppTypography.monoLarge.copyWith(
                      fontSize: 28,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Show this code at the counter',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            CgeButton(
              label: 'Done',
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                context.go('/'); // go home
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Booking failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Session'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          _ProgressIndicator(step: _step),

          // Step content
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                // Do not paint previous steps underneath the new step. In a
                // booking/payment flow, overlapping cards read as a broken UI.
                layoutBuilder: (currentChild, previousChildren) =>
                    currentChild ?? const SizedBox.shrink(),
                child: _buildStepContent(),
              ),
            ),
          ),

          // Bottom bar with total + next button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: AppTypography.labelSmall),
                        Text(
                          Pricing.formatPrice(_grandTotal),
                          style: AppTypography.monoLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                  Expanded(
                    flex: _step == 0 ? 1 : 0,
                    child: CgeButton(
                      label: _step == 3 ? 'Confirm Booking' : 'Next',
                      onPressed: _canProceed && !_isProcessing
                          ? _nextStep
                          : null,
                      isLoading: _isProcessing,
                      fullWidth: _step == 0,
                      size: CgeButtonSize.lg,
                      icon: _step < 3
                          ? LucideIcons.arrowRight
                          : LucideIcons.check,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _ZoneSelection(
          key: const ValueKey('zone'),
          selectedZone: _selectedZone,
          onSelect: (zone) => setState(() {
            _selectedZone = zone;
            _selectedGame = null; // reset game when zone changes
          }),
        );
      case 1:
        return _GameSchedule(
          key: const ValueKey('game'),
          games: _gamesForZone,
          selectedGame: _selectedGame,
          selectedDate: _selectedDate,
          selectedTimeSlot: _selectedTimeSlot,
          duration: _duration,
          zoneId: _selectedZone!,
          onGameSelect: (g) => setState(() => _selectedGame = g),
          onDateSelect: (d) => setState(() => _selectedDate = d),
          onTimeSelect: (t) => setState(() => _selectedTimeSlot = t),
          onDurationChange: (d) => setState(() => _duration = d),
        );
      case 2:
        return _DrinksAddOns(
          key: const ValueKey('drinks'),
          addOns: _addOns,
          onUpdate: (name, qty) => setState(() {
            if (qty <= 0) {
              _addOns.remove(name);
            } else {
              _addOns[name] = qty;
            }
          }),
        );
      case 3:
        return _PaymentSummary(
          key: const ValueKey('payment'),
          zone: AppConstants.zones.firstWhere((z) => z.id == _selectedZone),
          game: _selectedGame!,
          date: _selectedDate,
          timeSlot: _selectedTimeSlot!,
          duration: _duration,
          addOns: _addOns,
          sessionTotal: _sessionTotal,
          addOnsTotal: _addOnsTotal,
          grandTotal: _grandTotal,
          paymentMethod: _paymentMethod,
          onPaymentMethodChange: (method) =>
              setState(() => _paymentMethod = method),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Progress Indicator ──────────────────────────────

class _ProgressIndicator extends StatelessWidget {
  final int step;
  const _ProgressIndicator({required this.step});

  static const _labels = ['Zone', 'Schedule', 'Add-ons', 'Payment'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.cyan : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _labels[i],
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive
                              ? AppColors.cyan
                              : AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Zone Selection ──────────────────────────

class _ZoneSelection extends StatelessWidget {
  final String? selectedZone;
  final ValueChanged<String> onSelect;

  const _ZoneSelection({super.key, this.selectedZone, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Choose your zone', style: AppTypography.heading),
        const SizedBox(height: 4),
        Text(
          'Select where you want to play',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        ...AppConstants.zones.map((zone) {
          final isSelected = zone.id == selectedZone;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CgeCard(
              showGlow: isSelected,
              onTap: () => onSelect(zone.id),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (isSelected
                          ? AppColors.cyan
                          : AppColors.surfaceAlt),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        zone.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.name, style: AppTypography.subheading),
                        const SizedBox(height: 2),
                        Text(zone.description, style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CgeBadge(
                              label: zone.console,
                              color: BadgeColor.cyan,
                              fontSize: 10,
                            ),
                            const SizedBox(width: 8),
                            CgeBadge(
                              label: '${zone.capacity} players',
                              color: BadgeColor.magenta,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(LucideIcons.checkCircle2, color: AppColors.cyan),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Step 2: Game & Schedule ─────────────────────────

class _GameSchedule extends StatelessWidget {
  final List<String> games;
  final String? selectedGame;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final int duration;
  final String zoneId;
  final ValueChanged<String> onGameSelect;
  final ValueChanged<DateTime> onDateSelect;
  final ValueChanged<String> onTimeSelect;
  final ValueChanged<int> onDurationChange;

  const _GameSchedule({
    super.key,
    required this.games,
    this.selectedGame,
    required this.selectedDate,
    this.selectedTimeSlot,
    required this.duration,
    required this.zoneId,
    required this.onGameSelect,
    required this.onDateSelect,
    required this.onTimeSelect,
    required this.onDurationChange,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Game selection
        Text('Select game', style: AppTypography.subheading),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: games.map((game) {
            final isSelected = game == selectedGame;
            return ChoiceChip(
              label: Text(game),
              selected: isSelected,
              selectedColor: AppColors.cyan.withValues(alpha: 0.2),
              onSelected: (_) => onGameSelect(game),
              side: BorderSide(
                color: isSelected ? AppColors.cyan : AppColors.border,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Date picker
        Text('Select date', style: AppTypography.subheading),
        const SizedBox(height: 12),
        CgeCard(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.cyan,
                    surface: AppColors.surface,
                  ),
                ),
                child: child!,
              ),
            );
            if (date != null) onDateSelect(date);
          },
          child: Row(
            children: [
              const Icon(LucideIcons.calendar, color: AppColors.cyan, size: 20),
              const SizedBox(width: 12),
              Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: AppTypography.body,
              ),
              const Spacer(),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Time slots
        Text('Select time', style: AppTypography.subheading),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: AppConstants.timeSlots.map((slot) {
              final isSelected = slot == selectedTimeSlot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                  onSelected: (_) => onTimeSelect(slot),
                  side: BorderSide(
                    color: isSelected ? AppColors.cyan : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Duration
        Text(
          zoneId == 'vr' ? 'Sessions (15 min each)' : 'Duration (hours)',
          style: AppTypography.subheading,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: duration > 1
                  ? () => onDurationChange(duration - 1)
                  : null,
              icon: const Icon(LucideIcons.minus),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceAlt,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '$duration',
                style: AppTypography.monoLarge.copyWith(fontSize: 24),
              ),
            ),
            IconButton(
              onPressed: duration < 6
                  ? () => onDurationChange(duration + 1)
                  : null,
              icon: const Icon(LucideIcons.plus),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceAlt,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Step 3: Drinks & Snacks ─────────────────────────

class _DrinksAddOns extends StatelessWidget {
  final Map<String, int> addOns;
  final void Function(String name, int qty) onUpdate;

  const _DrinksAddOns({
    super.key,
    required this.addOns,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = {...Pricing.drinks, ...Pricing.snacks};

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Add drinks & snacks', style: AppTypography.heading),
        const SizedBox(height: 4),
        Text(
          'Optional — skip if you don\'t need any',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        ...allItems.entries.map((entry) {
          final qty = addOns[entry.key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CgeCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: AppTypography.body),
                        Text(
                          Pricing.formatPrice(entry.value),
                          style: AppTypography.mono.copyWith(
                            color: AppColors.cyan,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: qty > 0
                        ? () => onUpdate(entry.key, qty - 1)
                        : null,
                    icon: const Icon(LucideIcons.minus, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceAlt,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$qty', style: AppTypography.mono),
                  ),
                  IconButton(
                    onPressed: () => onUpdate(entry.key, qty + 1),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Step 4: Payment Summary ─────────────────────────

class _PaymentSummary extends StatelessWidget {
  final Zone zone;
  final String game;
  final DateTime date;
  final String timeSlot;
  final int duration;
  final Map<String, int> addOns;
  final int sessionTotal;
  final int addOnsTotal;
  final int grandTotal;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChange;

  const _PaymentSummary({
    super.key,
    required this.zone,
    required this.game,
    required this.date,
    required this.timeSlot,
    required this.duration,
    required this.addOns,
    required this.sessionTotal,
    required this.addOnsTotal,
    required this.grandTotal,
    required this.paymentMethod,
    required this.onPaymentMethodChange,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text('Order Summary', style: AppTypography.heading),
        const SizedBox(height: 20),

        CgeCard(
          child: Column(
            children: [
              _SummaryRow('Zone', zone.name),
              _SummaryRow('Game', game),
              _SummaryRow('Date', '${date.day}/${date.month}/${date.year}'),
              _SummaryRow('Time', timeSlot),
              _SummaryRow(
                'Duration',
                zone.id == 'vr'
                    ? '$duration × 15 min'
                    : '$duration hr${duration > 1 ? 's' : ''}',
              ),
              const Divider(color: AppColors.border, height: 24),
              _SummaryRow(
                'Session',
                Pricing.formatPrice(sessionTotal),
                isBold: true,
              ),
              if (addOns.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...addOns.entries.map(
                  (e) => _SummaryRow(
                    '${e.key} × ${e.value}',
                    Pricing.formatPrice(
                      (Pricing.drinks[e.key] ?? Pricing.snacks[e.key] ?? 0) *
                          e.value,
                    ),
                  ),
                ),
                const Divider(color: AppColors.border, height: 24),
              ],
              _SummaryRow(
                'Total',
                Pricing.formatPrice(grandTotal),
                isBold: true,
                isTotal: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Payment method selector
        Text('Payment Method', style: AppTypography.subheading),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => onPaymentMethodChange('paystack'),
          child: _PaymentOption(
            icon: LucideIcons.creditCard,
            label: 'Pay with Card',
            subtitle: 'Paystack secure checkout',
            isSelected: paymentMethod == 'paystack',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onPaymentMethodChange('venue'),
          child: _PaymentOption(
            icon: LucideIcons.building2,
            label: 'Pay at Venue',
            subtitle: 'Get a passcode for walk-in',
            isSelected: paymentMethod == 'venue',
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isTotal;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTypography.subheading : AppTypography.body,
          ),
          Text(
            value,
            style: isTotal
                ? AppTypography.monoLarge
                : isBold
                ? AppTypography.mono.copyWith(color: AppColors.cyan)
                : AppTypography.mono,
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      showGlow: isSelected,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.cyan : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.subheading.copyWith(fontSize: 14),
                ),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              LucideIcons.checkCircle2,
              color: AppColors.cyan,
              size: 20,
            ),
        ],
      ),
    );
  }
}
