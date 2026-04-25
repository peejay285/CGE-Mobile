import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class _CommandAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final String? shortcut;

  const _CommandAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    this.shortcut,
  });
}

const _actions = [
  _CommandAction(
    icon: LucideIcons.calendarCheck,
    label: 'Book a Session',
    subtitle: 'Reserve a lounge slot',
    route: '/lounge',
    shortcut: 'B',
  ),
  _CommandAction(
    icon: LucideIcons.plusCircle,
    label: 'Create Listing',
    subtitle: 'Sell or swap an item',
    route: '/marketplace/create',
    shortcut: 'N',
  ),
  _CommandAction(
    icon: LucideIcons.store,
    label: 'Browse Marketplace',
    subtitle: 'Find games and gear',
    route: '/marketplace',
    shortcut: 'M',
  ),
  _CommandAction(
    icon: LucideIcons.trophy,
    label: 'Tournaments',
    subtitle: 'Esports brackets and signups',
    route: '/esports',
    shortcut: 'T',
  ),
  _CommandAction(
    icon: LucideIcons.users,
    label: 'Community',
    subtitle: 'Posts and discussions',
    route: '/community',
    shortcut: 'C',
  ),
  _CommandAction(
    icon: LucideIcons.messageSquare,
    label: 'Messages',
    subtitle: 'Chats and conversations',
    route: '/messages',
  ),
  _CommandAction(
    icon: LucideIcons.user,
    label: 'My Profile',
    subtitle: 'View your profile',
    route: '/profile',
    shortcut: 'P',
  ),
  _CommandAction(
    icon: LucideIcons.edit,
    label: 'Edit Profile',
    subtitle: 'Update your info',
    route: '/profile/edit',
  ),
  _CommandAction(
    icon: LucideIcons.calendarDays,
    label: 'My Bookings',
    subtitle: 'Upcoming and past sessions',
    route: '/profile/bookings',
  ),
  _CommandAction(
    icon: LucideIcons.package,
    label: 'My Listings',
    subtitle: 'Manage your marketplace items',
    route: '/profile/listings',
  ),
  _CommandAction(
    icon: LucideIcons.gift,
    label: 'Giveaway',
    subtitle: 'Enter active giveaways',
    route: '/giveaway',
    shortcut: 'G',
  ),
  _CommandAction(
    icon: LucideIcons.bot,
    label: 'AI Concierge',
    subtitle: 'Ask the CGE assistant',
    route: '/concierge',
    shortcut: 'A',
  ),
  _CommandAction(
    icon: LucideIcons.bell,
    label: 'Notifications',
    subtitle: 'Alerts and updates',
    route: '/notifications',
  ),
  _CommandAction(
    icon: LucideIcons.settings,
    label: 'Settings',
    subtitle: 'App preferences',
    route: '/profile/settings',
  ),
];

class CommandPalette extends StatefulWidget {
  const CommandPalette._();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommandPalette._(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  String _query = '';

  List<_CommandAction> get _filtered {
    if (_query.isEmpty) return _actions;
    final q = _query.toLowerCase();
    return _actions.where((a) {
      return a.label.toLowerCase().contains(q) ||
          a.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filtered;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Search actions...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.base,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Action list
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No actions found',
                      style: AppTypography.bodySmall,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final action = filtered[index];
                      return _ActionTile(
                        action: action,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(action.route);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _CommandAction action;
  final VoidCallback onTap;

  const _ActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withValues(alpha: 0.1),
        highlightColor: AppColors.accent.withValues(alpha: 0.1),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(action.label, style: AppTypography.label),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        action.subtitle,
                        style: AppTypography.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (action.shortcut != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.base,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    action.shortcut!,
                    style: AppTypography.labelSmall.copyWith(fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
