import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import '../../data/remote/supabase_config.dart';

/// Handles Paystack payments for bookings, tournaments, and events
class PaymentService {
  static const _publicKey = 'pk_test_bcbe1b99e6140b4fbdf655fa7211a98764825af4';
  static const _callbackUrl = 'https://cgelounge.com/api/paystack/callback';

  /// Process a payment using Paystack popup
  static Future<bool> pay({
    required BuildContext context,
    required int amountInKobo,
    required String email,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    bool success = false;

    try {
      await FlutterPaystackPlus.openPaystackPopup(
        customerEmail: email,
        amount: amountInKobo.toString(),
        reference: reference,
        publicKey: _publicKey,
        context: context,
        callBackUrl: _callbackUrl,
        metadata: metadata,
        onSuccess: () {
          success = true;
        },
        onClosed: () {
          success = false;
        },
      );
    } catch (e) {
      success = false;
    }

    return success;
  }

  /// Generate a unique payment reference
  static String generateReference(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = SupabaseConfig.currentUser?.id.substring(0, 8) ?? 'anon';
    return '${prefix}_${userId}_$timestamp';
  }

  /// Calculate amount in kobo (Paystack uses kobo = Naira * 100)
  static int toKobo(int naira) => naira * 100;
}
