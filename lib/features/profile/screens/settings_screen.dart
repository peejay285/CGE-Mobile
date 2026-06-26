import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';
import '../../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification toggles
  bool _bookingReminders = true;
  bool _swapProposals = true;
  bool _tournamentAlerts = true;
  bool _communityMentions = true;
  bool _marketing = true;

  // Privacy toggles
  bool _showOnlineStatus = true;
  bool _showProfilePublicly = true;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Notifications ---
            _SectionHeader(icon: LucideIcons.bell, label: 'Notifications'),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ToggleTile(
                    title: 'Booking reminders',
                    subtitle: 'Get notified before your sessions',
                    value: _bookingReminders,
                    onChanged: (v) => setState(() => _bookingReminders = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: 'Swap proposals',
                    subtitle: 'When someone proposes a swap',
                    value: _swapProposals,
                    onChanged: (v) => setState(() => _swapProposals = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: 'Tournament alerts',
                    subtitle: 'Upcoming tournaments & results',
                    value: _tournamentAlerts,
                    onChanged: (v) => setState(() => _tournamentAlerts = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: 'Community mentions',
                    subtitle: 'When someone mentions you',
                    value: _communityMentions,
                    onChanged: (v) => setState(() => _communityMentions = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: 'Marketing',
                    subtitle: 'Promos, events, and updates',
                    value: _marketing,
                    onChanged: (v) => setState(() => _marketing = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Appearance ---
            _SectionHeader(icon: LucideIcons.palette, label: 'Appearance'),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _ThemeChoice(
                    label: 'System',
                    icon: LucideIcons.smartphone,
                    selected: themeMode == ThemeMode.system,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.system),
                  ),
                  _ThemeChoice(
                    label: 'Light',
                    icon: LucideIcons.sun,
                    selected: themeMode == ThemeMode.light,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.light),
                  ),
                  _ThemeChoice(
                    label: 'Dark',
                    icon: LucideIcons.moon,
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Privacy ---
            _SectionHeader(icon: LucideIcons.shield, label: 'Privacy'),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ToggleTile(
                    title: 'Show online status',
                    subtitle: 'Let others see when you\'re online',
                    value: _showOnlineStatus,
                    onChanged: (v) => setState(() => _showOnlineStatus = v),
                  ),
                  const Divider(height: 1),
                  _ToggleTile(
                    title: 'Show profile publicly',
                    subtitle: 'Allow non-members to view your profile',
                    value: _showProfilePublicly,
                    onChanged: (v) => setState(() => _showProfilePublicly = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- About ---
            _SectionHeader(icon: LucideIcons.info, label: 'About'),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'App version',
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    trailing: Text(
                      '1.0.0',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Terms of Service',
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    trailing: const Icon(
                      LucideIcons.externalLink,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => _launchUrl('https://cgelounge.com/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Privacy Policy',
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    trailing: const Icon(
                      LucideIcons.externalLink,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => _launchUrl('https://cgelounge.com/privacy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Open Source Licenses',
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                    trailing: const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'CGE App',
                      applicationVersion: '1.0.0',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.cyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: AppColors.cyan,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : colors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: selected ? AppColors.accent : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SwitchListTile(
      title: Text(title, style: AppTypography.body.copyWith(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.cyan,
      inactiveTrackColor: colors.surfaceRaised,
    );
  }
}
