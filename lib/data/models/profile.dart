class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? gamertag;
  final String? bio;
  final String? favouriteGame;
  final int points;
  final int wins;
  final int losses;
  final int? teamId;
  final int? followerCount;
  final int? followingCount;
  final int? tournamentCount;
  final int? achievementCount;
  final int? totalListings;
  final int? totalSales;
  final int? totalSwaps;
  final double? avgRating;
  final int? ratingCount;
  final String? trustLevel; // new, verified, trusted, power
  final String? locationState;
  final String? locationCity;
  final double? locationLat;
  final double? locationLng;
  // Tier 4 — verified profile + premium
  final bool isAdmin;
  final bool isIdVerified;
  final String? idVerifiedAt;
  final String premiumTier; // 'free' | 'premium'
  final String? premiumExpiresAt;
  final String? fcmToken;
  final String createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.gamertag,
    this.bio,
    this.favouriteGame,
    this.points = 0,
    this.wins = 0,
    this.losses = 0,
    this.teamId,
    this.followerCount,
    this.followingCount,
    this.tournamentCount,
    this.achievementCount,
    this.totalListings,
    this.totalSales,
    this.totalSwaps,
    this.avgRating,
    this.ratingCount,
    this.trustLevel,
    this.locationState,
    this.locationCity,
    this.locationLat,
    this.locationLng,
    this.isAdmin = false,
    this.isIdVerified = false,
    this.idVerifiedAt,
    this.premiumTier = 'free',
    this.premiumExpiresAt,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isPremiumActive {
    if (premiumTier != 'premium') return false;
    if (premiumExpiresAt == null) return false;
    return DateTime.parse(premiumExpiresAt!).isAfter(DateTime.now());
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        gamertag: json['gamertag'] as String?,
        bio: json['bio'] as String?,
        favouriteGame: json['favourite_game'] as String?,
        points: json['points'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        teamId: json['team_id'] as int?,
        followerCount: json['follower_count'] as int?,
        followingCount: json['following_count'] as int?,
        tournamentCount: json['tournament_count'] as int?,
        achievementCount: json['achievement_count'] as int?,
        totalListings: json['total_listings'] as int?,
        totalSales: json['total_sales'] as int?,
        totalSwaps: json['total_swaps'] as int?,
        avgRating: (json['avg_rating'] as num?)?.toDouble(),
        ratingCount: json['rating_count'] as int?,
        trustLevel: json['trust_level'] as String?,
        locationState: json['location_state'] as String?,
        locationCity: json['location_city'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        isAdmin: json['is_admin'] as bool? ?? false,
        isIdVerified: json['is_id_verified'] as bool? ?? false,
        idVerifiedAt: json['id_verified_at'] as String?,
        premiumTier: (json['premium_tier'] as String?) ?? 'free',
        premiumExpiresAt: json['premium_expires_at'] as String?,
        fcmToken: json['fcm_token'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'gamertag': gamertag,
        'bio': bio,
        'favourite_game': favouriteGame,
        'points': points,
        'wins': wins,
        'losses': losses,
        'team_id': teamId,
        'location_state': locationState,
        'location_city': locationCity,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'fcm_token': fcmToken,
      };
}
