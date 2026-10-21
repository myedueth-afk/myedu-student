import 'package:eschool/data/models/paymentTransaction.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/paginationUtils.dart';
import 'package:flutter/material.dart';

class PaymentRepository {
  ///[Make it more flexible to support more payment method]
  Future<PaymentTransaction> confirmPayment(
      {required int paymentTransactionId}) async {
    try {
      final result = await Api.get(
          url: Api.confirmPayment,
          useAuthToken: true,
          queryParameters: {"payment_transaction_id": paymentTransactionId});

      return PaymentTransaction.fromJson(Map.from(result['data'] ?? {}));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Reads one page of transactions out of whichever shape the endpoint
  /// returned. Both `latest_only` variants are paginated.
  @visibleForTesting
  static Map<String, dynamic> parseTransactionsPage(dynamic data) {
    final page = readPagedData(data);

    return {
      "transactions": page.items
          .map((paymentTransaction) =>
              PaymentTransaction.fromJson(Map.from(paymentTransaction ?? {})))
          .toList(),
      "currentPage": page.currentPage,
      "totalPage": page.totalPage,
    };
  }

  /// One page of the user's payment transactions, alongside the paging
  /// position — same shape as the other paged endpoints in the app.
  Future<Map<String, dynamic>> getTransactionsPage({
    bool? fetchLatest,
    int? page,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getTransactions,
        queryParameters: {
          "latest_only": (fetchLatest ?? false) ? 1 : 0,
          if (page != null && page > 0) "page": page,
        },
        useAuthToken: true,
      );

      return parseTransactionsPage(result['data']);
    } catch (e) {
      debugPrint(e.toString());
      throw ApiException(e.toString());
    }
  }

  /// The transactions themselves, for callers that only need the newest ones
  /// and never page — the pending payment check before a fee payment, for one.
  Future<List<PaymentTransaction>> getTransactions({bool? fetchLatest}) async {
    final result = await getTransactionsPage(fetchLatest: fetchLatest);
    return result['transactions'] as List<PaymentTransaction>;
  }
}
