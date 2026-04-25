import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/marketplace_repository.dart';
import '../data/models/marketplace_listing.dart';

final marketplaceRepositoryProvider =
    Provider((_) => MarketplaceRepository());

final listingsProvider =
    FutureProvider.family<List<MarketplaceListing>, Map<String, String?>>(
        (ref, filters) async {
  return ref.read(marketplaceRepositoryProvider).getListings(
        category: filters['category'],
        listingType: filters['listingType'],
        search: filters['search'],
      );
});

final myListingsProvider =
    FutureProvider<List<MarketplaceListing>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getMyListings();
});

final savedListingsProvider =
    FutureProvider<List<MarketplaceListing>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getSavedListings();
});
