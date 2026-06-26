class PaymentReturn {
  final String type;
  final String? reference;
  final int? tournamentId;

  const PaymentReturn({required this.type, this.reference, this.tournamentId});

  String get route {
    switch (type) {
      case 'booking':
        return '/profile/bookings';
      case 'tournament':
      case 'tournament_team':
        return tournamentId == null ? '/esports' : '/esports/$tournamentId';
      case 'swap_assist':
        return '/profile/swaps';
      case 'premium':
        return '/profile/upgrade';
      case 'event':
        return '/events';
      default:
        return '/';
    }
  }

  static PaymentReturn? fromUri(Uri uri) {
    final isCgeReturn =
        uri.scheme == 'cge' &&
        (uri.host == 'payment-return' || uri.path == '/payment-return');
    if (!isCgeReturn) return null;

    final type = uri.queryParameters['payment_type'];
    if (type == null || type.isEmpty) return null;
    return PaymentReturn(
      type: type,
      reference: uri.queryParameters['payment_ref'],
      tournamentId: int.tryParse(uri.queryParameters['tournament_id'] ?? ''),
    );
  }
}
