import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_card.dart';
import '../../../widgets/cge_badge.dart';
import '../../../widgets/cge_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    // Not signed in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.user, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Sign in to continue',
                    style: AppTypography.headingSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Track bookings, manage listings, and more',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CgeButton(
                  label: 'Sign In',
                  onPressed: () => context.push('/auth'),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = user.userMetadata?['full_name'] as String? ?? 'Gamer';
    final gamertag = user.userMetadata?['gamertag'] as String?;
    final avatarUrl = user.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar & info
            CgeAvatar(imageUrl: avatarUrl, name: name, size: 80),
            const SizedBox(height: 12),
            Text(name, style: AppTypography.heading),
            if (gamertag != null) ...[
              const SizedBox(height: 4),
              Text('@$gamertag',
                  style: AppTypography.body.copyWith(color: AppColors.cyan)),
            ],
            const SizedBox(height: 4),
            Text(user.email ?? '', style: AppTypography.bodySmall),
            const SizedBox(height: 8),
            const CgeBadge(label: 'New Player', color: BadgeColor.cyan),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: const [
                _StatCard(
                    label: 'Points',
                    value: '0',
                    icon: LucideIcons.zap,
                    color: AppColors.gold),
                SizedBox(width: 8),
                _StatCard(
                    label: 'Wins',
                    value: '0',
                    icon: LucideIcons.trophy,
                    color: AppColors.green),
                SizedBox(width: 8),
                _StatCard(
                    label: 'Losses',
                    value: '0',
                    icon: LucideIcons.x,
                    color: AppColors.red),
              ],
            ),

            const SizedBox(height: 24),

            // Menu items
            _MenuItem(
              icon: LucideIcons.calendar,
              label: 'My Bookings',
              onTap: () => context.push('/profile/bookings'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.tag,
              label: 'My Listings',
              onTap: () => context.push('/profile/listings'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.trophy,
              label: 'My Tournaments',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.award,
              label: 'Achievements',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.ticket,
              label: 'Vouchers',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.edit,
              label: 'Edit Profile',
              onTap: () => context.push('/profile/edit'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.bell,
              label: 'Notifications',
              onTap: () => context.push('/profile/settings'),
            ),

            const SizedBox(height: 24),

            // Sign out
            CgeButton(
              label: 'Sign Out',
              variant: CgeButtonVariant.danger,
              fullWidth: true,
              icon: LucideIcons.logOut,
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
            ),

            const SizedBox(height: 16),

            Text(
              'CGE App v1.0.0',
              style: AppTypography.labelSmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CgeCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: AppTypography.mono
                    .copyWith(color: color, fontSize: 20)),
            Text(label,
                style: AppTypography.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CgeCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: AppTypography.subheading.copyWith(fontSize: 14)),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
