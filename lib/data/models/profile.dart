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
    this.fcmToken,
    required this.createdAt,
  });

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
        'fcm_token': fcmToken,
      };
}
