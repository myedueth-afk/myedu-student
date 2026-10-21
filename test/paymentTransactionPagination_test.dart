import 'package:eschool/cubits/latestPaymentTransactionCubit.dart';
import 'package:eschool/cubits/paymentTransactionsCubit.dart';
import 'package:eschool/data/models/paymentTransaction.dart';
import 'package:eschool/data/repositories/paymentRepository.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paginator `payment-transactions` actually returns, trimmed to the
/// fields the app reads.
Map<String, dynamic> _paginator({
  required List<Map<String, dynamic>> rows,
  required int currentPage,
  required int lastPage,
}) {
  return {
    'current_page': currentPage,
    'last_page': lastPage,
    'per_page': 15,
    'total': 44,
    'data': rows,
  };
}

Map<String, dynamic> _row(int id, String status) =>
    {'id': id, 'payment_status': status, 'amount': 100};

class _FakePaymentRepository extends PaymentRepository {
  final Map<int, List<Map<String, dynamic>>> pages;
  final int lastPage;
  Object? errorOnPage2;
  final List<int?> requestedPages = [];
  final List<bool?> latestFlags = [];

  _FakePaymentRepository({required this.pages, required this.lastPage});

  @override
  Future<Map<String, dynamic>> getTransactionsPage({
    bool? fetchLatest,
    int? page,
  }) async {
    requestedPages.add(page);
    latestFlags.add(fetchLatest);

    final requested = page ?? 1;
    if (requested == 2 && errorOnPage2 != null) {
      throw errorOnPage2!;
    }

    return PaymentRepository.parseTransactionsPage(
      _paginator(
        rows: pages[requested] ?? [],
        currentPage: requested,
        lastPage: lastPage,
      ),
    );
  }
}

void main() {
  group('PaymentRepository.parseTransactionsPage', () {
    test('reads the paginator the endpoint returns', () {
      final result = PaymentRepository.parseTransactionsPage(
        _paginator(
          rows: [_row(53, 'succeed'), _row(52, 'pending')],
          currentPage: 1,
          lastPage: 3,
        ),
      );

      expect((result['transactions'] as List<PaymentTransaction>).length, 2);
      expect(result['currentPage'], 1);
      expect(result['totalPage'], 3);
    });

    test('still reads a bare list, which is what the endpoint used to send',
        () {
      final result = PaymentRepository.parseTransactionsPage(
        [_row(53, 'succeed')],
      );

      expect((result['transactions'] as List<PaymentTransaction>).length, 1);
      expect(result['totalPage'], 1);
    });
  });

  group('LatestPaymentTransactionCubit', () {
    test('still finds a pending transaction inside a paginated response',
        () async {
      //this guard runs before every fee payment — if it cannot read the
      //response the parent is blocked from paying at all
      final cubit = LatestPaymentTransactionCubit(
        _FakePaymentRepository(
          pages: {
            1: [_row(53, 'succeed'), _row(50, pendingTransactionStatusKey)],
          },
          lastPage: 3,
        ),
      );

      cubit.fetchLatestPaymentTransactions();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<LatestPaymentTransactionFetchSuccess>());
      expect(cubit.doesUserHaveLatestPendingTransactions(), isTrue);
    });

    test('reports no pending transaction when none is on the page', () async {
      final cubit = LatestPaymentTransactionCubit(
        _FakePaymentRepository(
          pages: {
            1: [_row(53, 'succeed')],
          },
          lastPage: 1,
        ),
      );

      cubit.fetchLatestPaymentTransactions();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.doesUserHaveLatestPendingTransactions(), isFalse);
    });
  });

  group('PaymentTransactionsCubit paging', () {
    late _FakePaymentRepository repository;
    late PaymentTransactionsCubit cubit;

    setUp(() {
      repository = _FakePaymentRepository(
        pages: {
          1: List.generate(15, (i) => _row(53 - i, 'succeed')),
          2: List.generate(15, (i) => _row(38 - i, 'succeed')),
          3: List.generate(14, (i) => _row(23 - i, 'succeed')),
        },
        lastPage: 3,
      );
      cubit = PaymentTransactionsCubit(repository);
    });

    Future<void> loadFirstPage() async {
      cubit.fetchPaymentTransactions();
      await Future<void>.delayed(Duration.zero);
    }

    test('loads the first page and knows more exist', () async {
      await loadFirstPage();

      final state = cubit.state as PaymentTransactionsFetchSuccess;
      expect(state.paymentTransactions.length, 15);
      expect(state.totalPage, 3);
      expect(cubit.hasMore(), isTrue);
      expect(repository.requestedPages, [null]);
      expect(repository.latestFlags, [null],
          reason: 'the full list is not the latest-only variant');
    });

    test('appends each further page instead of replacing them', () async {
      await loadFirstPage();
      await cubit.fetchMorePaymentTransactions();
      await cubit.fetchMorePaymentTransactions();

      final state = cubit.state as PaymentTransactionsFetchSuccess;
      expect(state.paymentTransactions.length, 44, reason: '15 + 15 + 14');
      expect(cubit.hasMore(), isFalse);
      expect(repository.requestedPages, [null, 2, 3]);
    });

    test('does not request beyond the last page', () async {
      await loadFirstPage();
      await cubit.fetchMorePaymentTransactions();
      await cubit.fetchMorePaymentTransactions();
      await cubit.fetchMorePaymentTransactions();

      expect(repository.requestedPages, [null, 2, 3]);
    });

    test('keeps what is loaded when a page fails, and can retry', () async {
      repository.errorOnPage2 = ApiException('no internet');
      await loadFirstPage();
      await cubit.fetchMorePaymentTransactions();

      var state = cubit.state as PaymentTransactionsFetchSuccess;
      expect(state.paymentTransactions.length, 15);
      expect(state.moreTransactionsFetchError, isTrue);

      repository.errorOnPage2 = null;
      await cubit.fetchMorePaymentTransactions();

      state = cubit.state as PaymentTransactionsFetchSuccess;
      expect(state.paymentTransactions.length, 30);
      expect(state.moreTransactionsFetchError, isFalse);
    });
  });
}
