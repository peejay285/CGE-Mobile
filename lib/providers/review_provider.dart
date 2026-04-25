import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/review_repository.dart';
import '../data/models/review.dart';
import '../data/models/profile.dart';

final reviewRepositoryProvider = Provider((_) => ReviewRepository());

final sellerReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, sellerId) async {
  return ref.read(reviewRepositoryProvider).getSellerReviews(sellerId);
});

final sellerProfileProvider =
    FutureProvider.family<Profile?, String>((ref, sellerId) async {
  return ref.read(reviewRepositoryProvider).getSellerProfile(sellerId);
});
