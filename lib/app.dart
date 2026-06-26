import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/theme_provider.dart';

final paymentReturnProvider = StateProvider<PaymentReturn?>((_) => null);

class CgeLoungeApp extends ConsumerStatefulWidget {
  const CgeLoungeApp({super.key});

  @override
  ConsumerState<CgeLoungeApp> createState() => _CgeLoungeAppState();
}

class _CgeLoungeAppState extends ConsumerState<CgeLoungeApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final links = AppLinks();
      links.getInitialLink().then(_handleLink).catchError((Object error) {
        debugPrint('Initial link error: $error');
      });
      _linkSubscription = links.uriLinkStream.listen(
        _handleLink,
        onError: (Object error) => debugPrint('Link stream error: $error'),
      );
    }
  }

  void _handleLink(Uri? uri) {
    if (uri == null) return;
    final paymentReturn = PaymentReturn.fromUri(uri);
    if (paymentReturn == null) return;

    ref.read(paymentReturnProvider.notifier).state = paymentReturn;
    ref.invalidate(currentProfileProvider);
    ref.invalidate(userBookingsProvider);
    final tournamentId = paymentReturn.tournamentId;
    if (tournamentId != null) {
      ref.invalidate(tournamentDetailProvider(tournamentId));
      ref.invalidate(myTournamentRegistrationProvider(tournamentId));
      ref.invalidate(myTeamTournamentRegistrationProvider(tournamentId));
      ref.invalidate(tournamentPayoutDataProvider);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(routerProvider).go(paymentReturn.route);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CGE App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
