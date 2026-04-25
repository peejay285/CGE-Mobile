/// CGE App-wide constants
class AppConstants {
  AppConstants._();

  // Brand
  static const appName = 'CGE App';
  static const brandFull = 'Creative Gaming Entertainment';
  static const address = '1 IT William Street, Akiama, Bonny Island';
  static const phone = '08160658509';
  static const email = 'Creativegamingent@gmail.com';
  static const whatsapp = 'https://wa.me/2348160658509';
  static const agePolicy = '13+';

  // Hours
  static const weekdayHours = '10 AM – 9 PM';
  static const sundayHours = '1 PM – 9 PM';

  // Zones
  static const zones = [
    Zone(
      id: 'main',
      name: 'Main Lounge',
      console: 'PS4',
      capacity: 6,
      description: 'Classic gaming with friends',
      icon: '🎮',
    ),
    Zone(
      id: 'vip',
      name: 'VIP Lounge',
      console: 'PS5',
      capacity: 2,
      description: 'Premium next-gen experience',
      icon: '👑',
    ),
    Zone(
      id: 'vr',
      name: 'VR Zone',
      console: 'VR Headset',
      capacity: 1,
      description: 'Immersive virtual reality',
      icon: '🥽',
    ),
  ];

  // Games by zone
  static const mainLoungeGames = [
    'FC 25/26',
    'Tekken 8',
    'Mortal Kombat 1',
    'Call of Duty',
    'GTA V',
    'NBA 2K25',
    'WWE 2K25',
    'Need for Speed',
  ];

  static const vipLoungeGames = [
    'FC 25/26',
    'Tekken 8',
    'Mortal Kombat 1',
    'Call of Duty',
    'GTA V',
    'NBA 2K25',
    'Spider-Man 2',
    'God of War Ragnarök',
  ];

  static const vrGames = [
    'Beat Saber',
    'Superhot VR',
    'Half-Life: Alyx',
    'VR Chat',
  ];

  // Marketplace categories
  static const marketplaceCategories = [
    'Controllers',
    'Games',
    'Accessories',
    'Furniture',
    'Consoles',
  ];

  // Marketplace conditions
  static const conditions = ['New', 'Like New', 'Good', 'Fair'];

  // Listing types
  static const listingTypes = ['swap', 'sell_or_swap', 'sell'];

  // Swap suggestions
  static const swapSuggestions = [
    'PS5 Controller',
    'Xbox Controller',
    'Gaming Headset',
    'FIFA/FC 26',
    'GTA VI',
    'Gaming Mouse',
    'Mechanical Keyboard',
    'Gaming Monitor',
    'PS5 Console',
    'Xbox Series X',
    'Nintendo Switch',
    'VR Headset',
    'Gaming Chair',
    'Any PS5 Game',
    'Any Xbox Game',
  ];

  // Tournament formats
  static const tournamentFormats = [
    'Single Elimination',
    'Double Elimination',
    'Round Robin',
    'Swiss',
  ];

  // Tournament platforms
  static const platforms = ['PS4', 'PS5', 'PC', 'Xbox', 'Mobile'];

  // Esports games
  static const esportsGames = [
    'FC 26',
    'Tekken 8',
    'Mortal Kombat 1',
    'Call of Duty',
  ];

  // Community topics
  static const communityTopics = [
    'general',
    'gaming-news',
    'lfg',
    'clips',
    'memes',
    'marketplace-talk',
    'tournament-talk',
    'tech-talk',
    'introductions',
  ];

  // Reactions
  static const reactions = ['🔥', '😂', '🤯', '😢', '😠', '❤️', 'GG'];

  // Time slots
  static const timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];
}

/// Zone model for lounge booking
class Zone {
  final String id;
  final String name;
  final String console;
  final int capacity;
  final String description;
  final String icon;

  const Zone({
    required this.id,
    required this.name,
    required this.console,
    required this.capacity,
    required this.description,
    required this.icon,
  });
}
