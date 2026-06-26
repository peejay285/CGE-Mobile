import 'package:url_launcher/url_launcher.dart';

import '../network/cge_api_client.dart';

/// Starts server-owned Paystack payments.
///
/// The server resolves the amount from the stored record, verifies ownership,
/// creates the Paystack reference, and relies on the webhook as the source of
/// truth. The mobile client never supplies a charge amount.
class PaymentService {
  PaymentService._();

  static int toKobo(int naira) => naira * 100;

  static Future<String> initializeRecordPayment({
    required String type,
    required String recordId,
    Map<String, dynamic>? metadata,
  }) async {
    final idKey = type == 'booking'
        ? 'booking_id'
        : type == 'swap_assist'
        ? 'assist_payment_id'
        : 'registration_id';
    final response = await CgeApiClient.post(
      '/api/paystack/initialize',
      body: {
        'type': type,
        'client': 'mobile',
        'metadata': {idKey: recordId, ...?metadata},
      },
    );
    final url = response['authorization_url'];
    if (url is! String || url.isEmpty) {
      throw const CgeApiException('Payment server returned an invalid URL');
    }
    return url;
  }

  static Future<String> initializePremiumPayment() async {
    final response = await CgeApiClient.post(
      '/api/premium/initialize',
      body: const {'client': 'mobile'},
    );
    final url = response['authorization_url'];
    if (url is! String || url.isEmpty) {
      throw const CgeApiException('Payment server returned an invalid URL');
    }
    return url;
  }

  static Future<void> openCheckout(String authorizationUrl) async {
    final launched = await launchUrl(
      Uri.parse(authorizationUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const CgeApiException('Could not open Paystack checkout');
    }
  }
}
