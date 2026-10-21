import 'package:dio/dio.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/models/paymentTransaction.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/paginationUtils.dart';
import 'package:flutter/foundation.dart';

class FeeRepository {
  /// Reads one page of fees out of whichever shape the endpoint returned.
  ///
  /// Kept apart from the request so the shape handling can be exercised
  /// directly — casting the paginator straight to a list is what broke the fee
  /// list, and a unit test is the cheapest guard against it coming back.
  @visibleForTesting
  static Map<String, dynamic> parseFeesPage(dynamic data) {
    final page = readPagedData(data);

    return {
      "fees": page.items
          .map((e) => ChildFeeDetails.fromJson(Map.from(e ?? {})))
          .toList(),
      "currentPage": page.currentPage,
      "totalPage": page.totalPage,
    };
  }

  //
  /// One page of a child's fees, alongside the paging position.
  ///
  /// Shaped like the other paged endpoints in the app (assignments,
  /// announcements, results) so the cubit and the list behave the same way.
  ///
  /// The endpoint hands back a paginator, but has also served the bare list in
  /// the past, so both are read rather than cast blind — a list arriving where
  /// a paginator was expected is what silently broke this screen before.
  Future<Map<String, dynamic>> fetchChildFeeDetails({
    required int childId,
    int? sessionYearId,
    int? page,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getStudentFeesDetailParent,
        useAuthToken: true,
        queryParameters: {
          "child_id": childId,
          if (sessionYearId != null) "session_year_id": sessionYearId,
          if (page != null && page > 0) "page": page,
        },
      );

      return parseFeesPage(result['data']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      throw ApiException(e.toString());
    }
  }

  /// Ceiling on the paging walk in [fetchChildFee], so a wrongly reported
  /// `totalPage` cannot turn one screen opening into endless requests.
  static const int _maxFeeLookupPages = 20;

  /// The current state of one fee, read back from the server.
  ///
  /// There is no single fee endpoint — `parent/fees` serves a page of them —
  /// so this walks the pages until the id turns up, almost always on the first.
  ///
  /// Null when the fee is no longer listed at all, which the caller reads as
  /// "keep showing what you have" rather than as an error.
  Future<ChildFeeDetails?> fetchChildFee({
    required int childId,
    required int feeId,
    int? sessionYearId,
  }) async {
    var page = 1;
    var totalPage = 1;

    while (page <= totalPage && page <= _maxFeeLookupPages) {
      final result = await fetchChildFeeDetails(
        childId: childId,
        sessionYearId: sessionYearId,
        //the first page is asked for the way the list asks for it
        page: page == 1 ? null : page,
      );

      for (final fee in result['fees'] as List<ChildFeeDetails>) {
        if (fee.id == feeId) {
          return fee;
        }
      }

      totalPage = result['totalPage'] as int;
      page++;
    }

    return null;
  }

  Future<({PaymentTransaction paymentTransaction, Map<String, dynamic> data})>
      payCompulsoryFee(
          {required String paymentMethod,
          required int childId,
          required int feeId,
          List<int>? installmentIds,
          double? advanceAmount}) async {
    try {
      final result = await Api.post(body: {
        "payment_method": paymentMethod,
        "child_id": childId,
        "fees_id": feeId,
        "installment_ids": installmentIds ?? [],
        "advance": advanceAmount ?? 0
      }, url: Api.payChildCompulsoryFees, useAuthToken: true);

      if (kDebugMode) {
        debugPrint("API Response for $paymentMethod: $result");
      }

      // Extract payment transaction
      final paymentTransaction = PaymentTransaction.fromJson(
          Map.from(result['data']['payment_transaction'] ?? {}));

      // Extract payment data based on payment method
      Map<String, dynamic> data;
      if (paymentMethod == "Flutterwave" ||
          paymentMethod == "Paystack" ||
          paymentMethod == "Chapa") {
        // For Flutterwave, Paystack, and Chapa, we need the entire data object as it contains the payment_link
        data = Map<String, dynamic>.from(result['data'] ?? {});

        if (kDebugMode) {
          debugPrint("Extracted payment data for $paymentMethod: $data");
        }
      } else {
        // For Stripe/Razorpay, extract payment_intent as before
        data =
            Map<String, dynamic>.from(result['data']['payment_intent'] ?? {});
      }

      return (paymentTransaction: paymentTransaction, data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in payCompulsoryFee: $e");
      }
      throw ApiException(e.toString());
    }
  }

  Future<({PaymentTransaction paymentTransaction, Map<String, dynamic> data})>
      payOptionalFees(
          {required String paymentMethod,
          required int childId,
          required int feeId,
          required List<int> optionalFeeIds}) async {
    try {
      final result = await Api.post(body: {
        "payment_method": paymentMethod,
        "child_id": childId,
        "fees_id": feeId,
        "optional_id": optionalFeeIds
      }, url: Api.payChildOptionalFees, useAuthToken: true);

      if (kDebugMode) {
        debugPrint(
            "API Response for optional fees with $paymentMethod: $result");
      }

      // Extract payment transaction
      final paymentTransaction = PaymentTransaction.fromJson(
          Map.from(result['data']['payment_transaction'] ?? {}));

      // Extract payment data based on payment method
      Map<String, dynamic> data;
      if (paymentMethod == "Flutterwave" ||
          paymentMethod == "Paystack" ||
          paymentMethod == "Chapa") {
        // For Flutterwave, Paystack, and Chapa, we need the entire data object as it contains the payment_link
        data = Map<String, dynamic>.from(result['data'] ?? {});

        if (kDebugMode) {
          debugPrint("Extracted payment data for $paymentMethod: $data");
        }
      } else {
        // For Stripe/Razorpay, extract payment_intent as before
        data =
            Map<String, dynamic>.from(result['data']['payment_intent'] ?? {});
      }

      return (paymentTransaction: paymentTransaction, data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in payOptionalFees: $e");
      }
      throw ApiException(e.toString());
    }
  }

  /// Records a compulsory fee the parent already paid the school directly.
  ///
  /// Unlike [payCompulsoryFee] there is no gateway involved, so nothing comes
  /// back to hand off to an SDK — the receipt is filed for the school to
  /// verify and the fee stays unpaid until they approve it.
  Future<void> payCompulsoryFeeManually({
    required int childId,
    required int feeId,
    required String receiptFilePath,
    List<int>? installmentIds,
    double? advanceAmount,
    String? notes,
  }) async {
    try {
      await Api.post(
        url: Api.payChildCompulsoryFeesManual,
        useAuthToken: true,
        body: {
          "child_id": childId,
          "fees_id": feeId,
          "installment_ids": installmentIds ?? [],
          "advance": advanceAmount ?? 0,
          "receipt": await MultipartFile.fromFile(receiptFilePath),
          if ((notes ?? "").trim().isNotEmpty) "notes": notes!.trim(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in payCompulsoryFeeManually: $e");
      }
      throw ApiException(e.toString());
    }
  }

  /// Records optional fees the parent already paid the school directly.
  ///
  /// The endpoint requires at least one optional fee id, and takes no advance
  /// — optional fees are never paid in installments.
  Future<void> payOptionalFeesManually({
    required int childId,
    required int feeId,
    required List<int> optionalFeeIds,
    required String receiptFilePath,
    String? notes,
  }) async {
    try {
      await Api.post(
        url: Api.payChildOptionalFeesManual,
        useAuthToken: true,
        body: {
          "child_id": childId,
          "fees_id": feeId,
          "optional_id": optionalFeeIds,
          "receipt": await MultipartFile.fromFile(receiptFilePath),
          if ((notes ?? "").trim().isNotEmpty) "notes": notes!.trim(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in payOptionalFeesManually: $e");
      }
      throw ApiException(e.toString());
    }
  }

  ///[Reads one page of a child's fee transaction history]
  @visibleForTesting
  static Map<String, dynamic> parseFeeTransactionsPage(dynamic data) {
    final page = readPagedData(data);

    return {
      "transactions": page.items
          .map((e) => FeeTransaction.fromJson(Map.from(e ?? {})))
          .toList(),
      "currentPage": page.currentPage,
      "totalPage": page.totalPage,
    };
  }

  /// One page of a child's fee payment history, alongside the paging position
  /// — same shape as the other paged endpoints in the app.
  ///
  /// [feesId] narrows the history to a single fee. Without it the endpoint
  /// returns every payment across every fee, which is the whole history rather
  /// than the answer to "what happened to the receipt I sent for this fee".
  Future<Map<String, dynamic>> getFeeTransactionsPage({
    required int childId,
    int? feesId,
    int? page,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getFeesTransactions,
        useAuthToken: true,
        queryParameters: {
          "child_id": childId,
          if (feesId != null && feesId > 0) "fees_id": feesId,
          if (page != null && page > 0) "page": page,
        },
      );

      return parseFeeTransactionsPage(result['data']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in getFeeTransactionsPage: $e");
      }
      throw ApiException(e.toString());
    }
  }

  /// The receipt for a settled payment, as base64 pdf content.
  ///
  /// A gateway or cash payment carries no receipt on the transaction itself —
  /// only the ids needed to ask for one — so this is fetched on demand when
  /// the parent asks for it, not up front for a list they may never open.
  ///
  /// Answers in exactly the shape [getFeeReceipt] does, so the two receipts are
  /// written out and opened by the same steps.
  ///
  /// [type] is the transaction's own `type` (`compulsory` / `optional`), and
  /// [transactionId] its `payment_transaction_id` — the receipt is filed
  /// against the payment transaction, not against the fee row that names it.
  Future<String> getTransactionReceipt({
    required String type,
    required int transactionId,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getFeeTransactionReceipt,
        useAuthToken: true,
        queryParameters: {
          "type": type,
          "transaction_id": transactionId,
        },
      );

      return parseTransactionReceiptContent(result);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error in getTransactionReceipt: $e");
      }
      throw ApiException(e.toString());
    }
  }

  /// Reads the base64 pdf out of the endpoint's envelope.
  ///
  /// Empty when the school could not produce a receipt, which the caller
  /// reports as unavailable rather than writing out a file that opens to
  /// nothing.
  @visibleForTesting
  static String parseTransactionReceiptContent(dynamic result) {
    if (result is! Map) {
      return '';
    }

    return (result['pdf'] ?? '').toString().trim();
  }

  Future<String> getFeeReceipt(
      {required int childId, required int feeId}) async {
    try {
      final result = await Api.get(queryParameters: {
        "child_id": childId,
        "fees_id": feeId,
      }, url: Api.downloadFeeReceipt, useAuthToken: true);

      return result['pdf'] ?? "";
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
