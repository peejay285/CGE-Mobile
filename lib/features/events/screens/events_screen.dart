import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _typeFilter = 'All';
  bool _isCalendarView = false;

  static const _typeFilters = ['All', 'Party', 'Special', 'Demo', 'Package'];

  static final _mockEvents = [
    _MockEvent(
      'CGE Glow Party',
      'Party',
      DateTime(2026, 3, 22, 20, 0),
      DateTime(2026, 3, 22, 23, 59),
      5000,
      50,
      38,
      'Neon lights, music, and gaming all night long. Dress code: glow-in-the-dark.',
    ),
    _MockEvent(
      'FIFA Tournament Special',
      'Special',
      DateTime(2026, 3, 25, 14, 0),
      DateTime(2026, 3, 25, 18, 0),
      0,
      30,
      12,
      'Special FC 26 tournament with exclusive prizes for top 3.',
    ),
    _MockEvent(
      'PS VR2 Demo Day',
      'Demo',
      DateTime(2026, 3, 28, 10, 0),
      DateTime(2026, 3, 28, 17, 0),
      0,
      20,
      15,
      'Try out the latest PS VR2 titles. First come, first served.',
    ),
    _MockEvent(
      'Weekend Gaming Package',
      'Package',
      DateTime(2026, 4, 4, 12, 0),
      DateTime(2026, 4, 4, 22, 0),
      8000,
      40,
      40,
      '10 hours of gaming + snacks + drinks. Best value deal.',
    ),
    _MockEvent(
      'Ladies Night Gaming',
      'Party',
      DateTime(2026, 4, 10, 18, 0),
      DateTime(2026, 4, 10, 22, 0),
      3000,
      25,
      9,
      'Exclusive gaming night for the ladies. Cocktails and controllers.',
    ),
  ];

  List<_MockEvent> get _filteredEvents {
    if (_typeFilter == 'All') return _mockEvents;
    return _mockEvents.where((e) => e.type == _typeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCalendarView ? LucideIcons.list : LucideIcons.calendarDays,
              size: 20,
            ),
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
          ),
        ],
      ),
      body: Column(
        children: [
          // View toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ViewToggle(
                  icon: LucideIcons.list,
                  label: 'List',
                  isActive: !_isCalendarView,
                  onTap: () => setState(() => _isCalendarView = false),
                ),
                const SizedBox(width: 8),
                _ViewToggle(
                  icon: LucideIcons.calendarDays,
                  label: 'Calendar',
                  isActive: _isCalendarView,
                  onTap: () => setState(() => _isCalendarView = true),
                ),
              ],
            ),
          ),

          // Type filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _typeFilters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _typeFilter == f,
                          selectedColor: AppColors.cyan.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _typeFilter = f),
                          side: BorderSide(
                            color: _typeFilter == f
                                ? AppColors.cyan
                                : AppColors.border,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _isCalendarView
                ? _CalendarView(events: _filteredEvents)
                : _ListView(events: _filteredEvents),
          ),
        ],
      ),
    );
  }
}

// ─── View Toggle Button ─────────────────────────────

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.cyan : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? AppColors.cyan : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? AppColors.cyan : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List View ──────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<_MockEvent> events;

  const _ListView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No events found', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Check back later for upcoming events',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, i) => _EventCard(event: events[i]),
    );
  }
}

// ─── Calendar View ──────────────────────────────────

class _CalendarView extends StatelessWidget {
  final List<_MockEvent> events;

  const _CalendarView({required this.events});

  @override
  Widget build(BuildContext context) {
    // Group events by date
    final grouped = <String, List<_MockEvent>>{};
    for (final event in events) {
      final key = _formatDateKey(event.startTime);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    if (sortedKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No events found', style: AppTypography.headingSmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final dateKey = sortedKeys[i];
        final dateEvents = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: AppColors.cyan),
                  const SizedBox(width: 8),
                  Text(
                    dateKey,
                    style: AppTypography.label.copyWith(color: AppColors.cyan),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: AppColors.border,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...dateEvents.map((e) => _EventCard(event: e)),
          ],
        );
      },
    );
  }

  String _formatDateKey(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month]} ${dt.day}';
  }
}

// ─── Event Card ─────────────────────────────────────

class _EventCard extends StatelessWidget {
  final _MockEvent event;

  const _EventCard({required this.event});

  BadgeColor get _typeBadgeColor {
    switch (event.type) {
      case 'Party':
        return BadgeColor.magenta;
      case 'Special':
        return BadgeColor.gold;
      case 'Demo':
        return BadgeColor.cyan;
      case 'Package':
        return BadgeColor.green;
      default:
        return BadgeColor.cyan;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  bool get _isFull => event.registered >= event.capacity;

  @override
  Widget build(BuildContext context) {
    final capacityRatio = event.registered / event.capacity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CgeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + type badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: AppTypography.subheading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CgeBadge(
                  label: event.type,
                  color: _typeBadgeColor,
                  fontSize: 10,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & time row
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatDate(event.startTime),
                  style: AppTypography.labelSmall.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(LucideIcons.clock, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: AppTypography.labelSmall.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              event.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Bottom row: price + capacity
            Row(
              children: [
                // Price
                if (event.price > 0) ...[
                  Icon(LucideIcons.banknote, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    '\u20A6${_formatPrice(event.price)}',
                    style: AppTypography.mono
                        .copyWith(color: AppColors.gold, fontSize: 13),
                  ),
                ] else
                  const CgeBadge(
                      label: 'FREE', color: BadgeColor.green, fontSize: 10),
                const Spacer(),
                // Capacity tracker
                Icon(LucideIcons.users, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${event.registered}/${event.capacity} registered',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Capacity progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: capacityRatio,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isFull ? AppColors.red : AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Register button
            CgeButton(
              label: _isFull ? 'Sold Out' : 'Register',
              onPressed: _isFull ? null : () {},
              fullWidth: true,
              size: CgeButtonSize.sm,
              variant:
                  _isFull ? CgeButtonVariant.secondary : CgeButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)},${(price % 1000).toString().padLeft(3, '0')}'
          .replaceAll(RegExp(r',000$'), ',000');
    }
    return price.toString();
  }
}

// ─── Mock Data ──────────────────────────────────────

class _MockEvent {
  final String title;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final int price;
  final int capacity;
  final int registered;
  final String description;

  _MockEvent(
    this.title,
    this.type,
    this.startTime,
    this.endTime,
    this.price,
    this.capacity,
    this.registered,
    this.description,
  );
}
