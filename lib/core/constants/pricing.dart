/// Centralized pricing logic — single source of truth
class Pricing {
  Pricing._();

  // Main Lounge (per hour)
  static int mainLoungePrice(String game) {
    if (game.contains('FC') || game.contains('FIFA')) return 3000;
    return 2000;
  }

  // VIP Lounge (per hour)
  static const vipSingleConsole = 5000;
  static const vipBothConsoles = 10000;

  // VR Zone (per 15-min session)
  static const vrSession = 2000;

  // Drinks
  static const drinks = {
    'Coca-Cola': 500,
    'Fanta': 500,
    'Sprite': 500,
    'Water': 500,
    'Red Bull': 1000,
    'Monster': 1000,
  };

  // Snacks
  static const snacks = {
    'Chin Chin': 300,
    'Pringles': 800,
    'Popcorn': 500,
  };

  /// Calculate session total based on zone and duration
  static int getSessionTotal({
    required String zoneId,
    required String game,
    required int duration,
  }) {
    switch (zoneId) {
      case 'main':
        return mainLoungePrice(game) * duration;
      case 'vip':
        return vipSingleConsole * duration;
      case 'vr':
        return vrSession * duration;
      default:
        return 0;
    }
  }

  /// Calculate add-ons total
  static int getAddOnsTotal(Map<String, int> items) {
    int total = 0;
    items.forEach((name, qty) {
      final price = drinks[name] ?? snacks[name] ?? 0;
      total += price * qty;
    });
    return total;
  }

  /// Format price as Nigerian Naira
  static String formatPrice(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₦$formatted';
  }
}
