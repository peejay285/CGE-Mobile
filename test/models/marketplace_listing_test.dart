import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/data/models/marketplace_listing.dart';

void main() {
  group('MarketplaceListing', () {
    group('fromJson', () {
      test('correctly parses all fields', () {
        final json = {
          'id': 'listing-001',
          'seller_id': 'user-abc',
          'title': 'PS5 Controller',
          'price': 25000,
          'condition': 'like_new',
          'category': 'controllers',
          'description': 'Barely used DualSense controller',
          'images': ['img1.jpg', 'img2.jpg'],
          'listing_type': 'sell',
          'swap_for': 'Xbox controller',
          'swap_for_tags': ['xbox', 'controller'],
          'buyout_price': 30000,
          'location': 'Lagos',
          'views_count': 42,
          'saves_count': 5,
          'user_has_saved': true,
          'status': 'active',
          'created_at': '2026-03-21T10:00:00Z',
          'profiles': {
            'id': 'user-abc',
            'full_name': 'John Doe',
            'created_at': '2026-01-01T00:00:00Z',
          },
        };

        final listing = MarketplaceListing.fromJson(json);

        expect(listing.id, 'listing-001');
        expect(listing.sellerId, 'user-abc');
        expect(listing.title, 'PS5 Controller');
        expect(listing.price, 25000);
        expect(listing.condition, 'like_new');
        expect(listing.category, 'controllers');
        expect(listing.description, 'Barely used DualSense controller');
        expect(listing.images, ['img1.jpg', 'img2.jpg']);
        expect(listing.listingType, 'sell');
        expect(listing.swapFor, 'Xbox controller');
        expect(listing.swapForTags, ['xbox', 'controller']);
        expect(listing.buyoutPrice, 30000);
        expect(listing.location, 'Lagos');
        expect(listing.viewsCount, 42);
        expect(listing.savesCount, 5);
        expect(listing.userHasSaved, isTrue);
        expect(listing.status, 'active');
        expect(listing.createdAt, '2026-03-21T10:00:00Z');
        expect(listing.seller, isNotNull);
        expect(listing.seller!.fullName, 'John Doe');
      });

      test('handles null optional fields (buyoutPrice, seller)', () {
        final json = {
          'id': 'listing-002',
          'seller_id': 'user-xyz',
          'title': 'Gaming Headset',
          'price': null,
          'condition': 'used',
          'category': 'accessories',
          'description': null,
          'images': null,
          'listing_type': 'swap',
          'swap_for': null,
          'swap_for_tags': null,
          'buyout_price': null,
          'location': null,
          'views_count': null,
          'saves_count': null,
          'user_has_saved': null,
          'status': 'active',
          'created_at': '2026-03-21T12:00:00Z',
        };

        final listing = MarketplaceListing.fromJson(json);

        expect(listing.price, isNull);
        expect(listing.description, isNull);
        expect(listing.buyoutPrice, isNull);
        expect(listing.location, isNull);
        expect(listing.seller, isNull);
        expect(listing.viewsCount, 0);
        expect(listing.savesCount, 0);
        expect(listing.userHasSaved, isFalse);
      });

      test('handles empty images and swapForTags lists', () {
        final json = {
          'id': 'listing-003',
          'seller_id': 'user-xyz',
          'title': 'Game Disc',
          'condition': 'good',
          'category': 'games',
          'listing_type': 'sell',
          'images': <dynamic>[],
          'swap_for_tags': <dynamic>[],
          'created_at': '2026-03-21T14:00:00Z',
        };

        final listing = MarketplaceListing.fromJson(json);

        expect(listing.images, isEmpty);
        expect(listing.swapForTags, isEmpty);
      });

      test('defaults status to active when null', () {
        final json = {
          'id': 'listing-004',
          'seller_id': 'user-xyz',
          'title': 'Monitor',
          'condition': 'new',
          'category': 'displays',
          'listing_type': 'sell',
          'status': null,
          'created_at': '2026-03-21T15:00:00Z',
        };

        final listing = MarketplaceListing.fromJson(json);

        expect(listing.status, 'active');
      });
    });

    group('toJson', () {
      test('produces expected output', () {
        const listing = MarketplaceListing(
          id: 'listing-001',
          sellerId: 'user-abc',
          title: 'PS5 Controller',
          price: 25000,
          condition: 'like_new',
          category: 'controllers',
          description: 'Barely used',
          images: ['img1.jpg'],
          listingType: 'sell',
          swapFor: 'Xbox controller',
          swapForTags: ['xbox'],
          buyoutPrice: 30000,
          location: 'Lagos',
          status: 'active',
          createdAt: '2026-03-21T10:00:00Z',
        );

        final json = listing.toJson();

        expect(json['seller_id'], 'user-abc');
        expect(json['title'], 'PS5 Controller');
        expect(json['price'], 25000);
        expect(json['condition'], 'like_new');
        expect(json['category'], 'controllers');
        expect(json['description'], 'Barely used');
        expect(json['images'], ['img1.jpg']);
        expect(json['listing_type'], 'sell');
        expect(json['swap_for'], 'Xbox controller');
        expect(json['swap_for_tags'], ['xbox']);
        expect(json['buyout_price'], 30000);
        expect(json['location'], 'Lagos');
        expect(json['status'], 'active');
        // toJson does not include id, created_at, views_count, saves_count, user_has_saved
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('views_count'), isFalse);
        expect(json.containsKey('saves_count'), isFalse);
      });
    });
  });
}
