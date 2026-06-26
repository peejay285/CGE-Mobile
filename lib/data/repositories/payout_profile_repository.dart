import '../../core/network/cge_api_client.dart';
import '../models/tournament_payout.dart';

class PayoutProfileRepository {
  Future<List<PaystackBank>> getBanks() async {
    final response = await CgeApiClient.get('/api/paystack/banks');
    final banks = response['banks'];
    if (banks is! List) {
      throw const CgeApiException('Bank server returned an invalid response');
    }
    return banks
        .map(
          (bank) =>
              PaystackBank.fromJson(Map<String, dynamic>.from(bank as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> saveRecipient({
    required String accountName,
    required String accountNumber,
    required String bankCode,
    required String bankName,
  }) {
    return CgeApiClient.post(
      '/api/payout-profile/recipient',
      body: {
        'account_name': accountName,
        'account_number': accountNumber,
        'bank_code': bankCode,
        'bank_name': bankName,
      },
    );
  }
}
