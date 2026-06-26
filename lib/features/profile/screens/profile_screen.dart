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
import '../../../widgets/cge_visual_banner.dart';
import '../../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final profile = ref.watch(currentProfileProvider).valueOrNull;

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
                CgeTintedIcon(
                  icon: LucideIcons.user,
                  color: AppColors.accent,
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to continue',
                  style: AppTypography.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Track bookings, manage listings, and more',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
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

    final name =
        profile?.fullName ??
        user.userMetadata?['full_name'] as String? ??
        'Gamer';
    final gamertag =
        profile?.gamertag ?? user.userMetadata?['gamertag'] as String?;
    final avatarUrl =
        profile?.avatarUrl ?? user.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
        actions: [
          IconButton(
            tooltip: 'Change appearance',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
              size: 20,
            ),
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggle(Theme.of(context).brightness),
          ),
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
            Container(
              height: 216,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: AssetImage('assets/images/community-hero.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0xED07111F)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: CgeAvatar(
                            imageUrl: avatarUrl,
                            name: name,
                            size: 72,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTypography.heading.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (gamertag != null)
                                Text(
                                  '@$gamertag',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              Text(
                                user.email ?? '',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CgeBadge(
              label: profile?.isAdmin == true
                  ? 'CGE Admin'
                  : profile?.trustLevel ?? 'New Player',
              color: profile?.isAdmin == true
                  ? BadgeColor.gold
                  : BadgeColor.cyan,
            ),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatCard(
                  label: 'Points',
                  value: '${profile?.points ?? 0}',
                  icon: LucideIcons.zap,
                  color: AppColors.gold,
                ),
                SizedBox(width: 8),
                _StatCard(
                  label: 'Wins',
                  value: '${profile?.wins ?? 0}',
                  icon: LucideIcons.trophy,
                  color: AppColors.green,
                ),
                SizedBox(width: 8),
                _StatCard(
                  label: 'Losses',
                  value: '${profile?.losses ?? 0}',
                  icon: LucideIcons.x,
                  color: AppColors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu items
            const _SectionTitle(
              title: 'Your activity',
              subtitle: 'Everything you are doing across CGE',
            ),
            const SizedBox(height: 10),
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
              icon: LucideIcons.repeat,
              label: 'My Swap Proposals',
              onTap: () => context.push('/profile/swaps'),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Account & rewards',
              subtitle: 'Trust, winnings and membership',
            ),
            const SizedBox(height: 10),
            _MenuItem(
              icon: LucideIcons.shieldCheck,
              label: 'Verify your profile',
              onTap: () => context.push('/profile/verification'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.crown,
              label: 'Premium',
              onTap: () => context.push('/profile/upgrade'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.landmark,
              label: 'Prize Payout Account',
              onTap: () => context.push('/profile/payout'),
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.trophy,
              label: 'My Tournaments',
              subtitle: 'Coming soon',
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.award,
              label: 'Achievements',
              subtitle: 'Coming soon',
            ),
            const SizedBox(height: 8),
            _MenuItem(
              icon: LucideIcons.ticket,
              label: 'Vouchers',
              subtitle: 'Coming soon',
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
            Text(
              value,
              style: AppTypography.mono.copyWith(color: color, fontSize: 20),
            ),
            Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = switch (icon) {
      LucideIcons.crown || LucideIcons.award => AppColors.gold,
      LucideIcons.repeat || LucideIcons.tag => AppColors.magenta,
      LucideIcons.trophy || LucideIcons.ticket => AppColors.violet,
      _ => AppColors.accent,
    };
    return CgeCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      onTap: onTap,
      child: Row(
        children: [
          CgeTintedIcon(icon: icon, color: accent, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.subheading.copyWith(fontSize: 14),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            onTap == null ? LucideIcons.clock3 : LucideIcons.chevronRight,
            size: 18,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.subheading.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
