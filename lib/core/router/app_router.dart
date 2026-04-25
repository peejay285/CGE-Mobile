import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/esports/screens/esports_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/lounge/screens/booking_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/marketplace/screens/listing_detail_screen.dart';
import '../../features/marketplace/screens/create_listing_screen.dart';
import '../../features/marketplace/screens/swap_proposal_screen.dart';
import '../../features/esports/screens/tournament_detail_screen.dart';
import '../../features/community/screens/post_detail_screen.dart';
import '../../features/marketplace/screens/seller_profile_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/giveaway/screens/giveaway_screen.dart';
import '../../features/concierge/screens/concierge_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/my_bookings_screen.dart';
import '../../features/profile/screens/my_listings_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/swap_proposals_screen.dart';
import '../../widgets/cge_bottom_nav.dart';
import '../../widgets/command_palette.dart';
import '../theme/app_colors.dart';

// Shell route key for bottom nav persistence
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds a CustomTransitionPage with a slide-from-right transition.
CustomTransitionPage<void> _slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Bottom nav shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/marketplace',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MarketplaceScreen(),
            ),
          ),
          GoRoute(
            path: '/esports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EsportsScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav) — slide-from-right transition
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/lounge',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const BookingScreen(),
        ),
      ),
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const CommunityScreen(),
        ),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const EventsScreen(),
        ),
      ),
      GoRoute(
        path: '/events/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: EventDetailScreen(
            eventId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/messages/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            conversationId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/marketplace/create',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const CreateListingScreen(),
        ),
      ),
      GoRoute(
        path: '/marketplace/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: ListingDetailScreen(
            listingId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/marketplace/:id/swap',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: SwapProposalScreen(
            listingId: state.pathParameters['id']!,
            listingTitle: state.uri.queryParameters['title'] ?? 'Listing',
          ),
        ),
      ),
      GoRoute(
        path: '/esports/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: TournamentDetailScreen(
            tournamentId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/community/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: PostDetailScreen(
            postId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/seller/:id',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: SellerProfileScreen(
            sellerId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/giveaway',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const GiveawayScreen(),
        ),
      ),
      GoRoute(
        path: '/concierge',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const ConciergeScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/bookings',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const MyBookingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/listings',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const MyListingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/settings',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/swaps',
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const SwapProposalsScreen(),
        ),
      ),
    ],
  );
});

/// Scaffold wrapper with persistent bottom navigation
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const CgeBottomNav(),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => CommandPalette.show(context),
        backgroundColor: AppColors.accent,
        child: const Icon(LucideIcons.search, size: 18, color: Color(0xFF09090B)),
      ),
    );
  }
}
