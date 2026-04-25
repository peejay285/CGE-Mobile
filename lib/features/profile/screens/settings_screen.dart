import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            _SectionHeader(
              icon: LucideIcons.bell,
              label: 'Notifications',
            ),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ToggleTile(
                    title: 'Booking reminders',
                    subtitle: 'Get notified before your sessions',
                    value: _bookingReminders,
                    onChanged: (v) =>
                        setState(() => _bookingReminders = v),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleTile(
                    title: 'Swap proposals',
                    subtitle: 'When someone proposes a swap',
                    value: _swapProposals,
                    onChanged: (v) =>
                        setState(() => _swapProposals = v),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleTile(
                    title: 'Tournament alerts',
                    subtitle: 'Upcoming tournaments & results',
                    value: _tournamentAlerts,
                    onChanged: (v) =>
                        setState(() => _tournamentAlerts = v),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleTile(
                    title: 'Community mentions',
                    subtitle: 'When someone mentions you',
                    value: _communityMentions,
                    onChanged: (v) =>
                        setState(() => _communityMentions = v),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleTile(
                    title: 'Marketing',
                    subtitle: 'Promos, events, and updates',
                    value: _marketing,
                    onChanged: (v) =>
                        setState(() => _marketing = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- Appearance ---
            _SectionHeader(
              icon: LucideIcons.palette,
              label: 'Appearance',
            ),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text('Dark mode',
                    style: AppTypography.body.copyWith(fontSize: 14)),
                subtitle: Text(
                  'CGE App is designed for dark mode',
                  style: AppTypography.bodySmall.copyWith(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.lock,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // --- Privacy ---
            _SectionHeader(
              icon: LucideIcons.shield,
              label: 'Privacy',
            ),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ToggleTile(
                    title: 'Show online status',
                    subtitle: 'Let others see when you\'re online',
                    value: _showOnlineStatus,
                    onChanged: (v) =>
                        setState(() => _showOnlineStatus = v),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleTile(
                    title: 'Show profile publicly',
                    subtitle: 'Allow non-members to view your profile',
                    value: _showProfilePublicly,
                    onChanged: (v) =>
                        setState(() => _showProfilePublicly = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --- About ---
            _SectionHeader(
              icon: LucideIcons.info,
              label: 'About',
            ),
            const SizedBox(height: 8),
            CgeCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text('App version',
                        style: AppTypography.body.copyWith(fontSize: 14)),
                    trailing: Text('1.0.0',
                        style: AppTypography.mono
                            .copyWith(color: AppColors.textMuted)),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: Text('Terms of Service',
                        style: AppTypography.body.copyWith(fontSize: 14)),
                    trailing: const Icon(LucideIcons.externalLink,
                        size: 16, color: AppColors.textMuted),
                    onTap: () =>
                        _launchUrl('https://cgelounge.com/terms'),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: Text('Privacy Policy',
                        style: AppTypography.body.copyWith(fontSize: 14)),
                    trailing: const Icon(LucideIcons.externalLink,
                        size: 16, color: AppColors.textMuted),
                    onTap: () =>
                        _launchUrl('https://cgelounge.com/privacy'),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    title: Text('Open Source Licenses',
                        style: AppTypography.body.copyWith(fontSize: 14)),
                    trailing: const Icon(LucideIcons.chevronRight,
                        size: 16, color: AppColors.textMuted),
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
    return SwitchListTile(
      title: Text(title,
          style: AppTypography.body.copyWith(fontSize: 14)),
      subtitle: Text(subtitle,
          style: AppTypography.bodySmall.copyWith(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.cyan,
      inactiveTrackColor: AppColors.surfaceAlt,
    );
  }
}
