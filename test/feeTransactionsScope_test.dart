import 'package:eschool/cubits/feeTransactionsCubit.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFeeRepository extends FeeRepository {
  final List<({int childId, int? feesId, int? page})> calls = [];
  final int lastPage;

  _RecordingFeeRepository({this.lastPage = 2});

  @override
  Future<Map<String, dynamic>> getFeeTransactionsPage({
    required int childId,
    int? feesId,
    int? page,
  }) async {
    calls.add((childId: childId, feesId: feesId, page: page));

    return FeeRepository.parseFeeTransactionsPage({
      'current_page': page ?? 1,
      'last_page': lastPage,
      'data': [
        {'id': 61, 'fee_name': 'Full Payment', 'mode': 'Manual'}
      ],
    });
  }
}

void main() {
  group('fee transaction history scope', () {
    test('asks only for the fee the parent opened', () async {
      final repository = _RecordingFeeRepository();
      final cubit = FeeTransactionsCubit(repository);

      cubit.fetchFeeTransactions(childId: 48, feesId: 24);
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls.single.childId, 48);
      expect(repository.calls.single.feesId, 24);
      //the first request must not name a page, so the endpoint's default applies
      expect(repository.calls.single.page, isNull);
    });

    test('keeps the fee scope when loading the next page', () async {
      final repository = _RecordingFeeRepository();
      final cubit = FeeTransactionsCubit(repository);

      cubit.fetchFeeTransactions(childId: 48, feesId: 24);
      await Future<void>.delayed(Duration.zero);
      await cubit.fetchMoreFeeTransactions();

      //dropping fees_id here would pull in payments made against other fees
      expect(repository.calls.map((c) => c.feesId).toList(), [24, 24]);
      expect(repository.calls.map((c) => c.page).toList(), [null, 2]);
    });

    test('leaves the scope off when no fee was named', () async {
      final repository = _RecordingFeeRepository(lastPage: 1);
      final cubit = FeeTransactionsCubit(repository);

      cubit.fetchFeeTransactions(childId: 48);
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls.single.feesId, isNull);
      expect(
        (cubit.state as FeeTransactionsFetchSuccess).transactions,
        isA<List<FeeTransaction>>(),
      );
    });

    test('keeps the fee scope when the parent pulls to refresh', () async {
      final repository = _RecordingFeeRepository();
      final cubit = FeeTransactionsCubit(repository);

      cubit.fetchFeeTransactions(childId: 48, feesId: 24);
      await Future<void>.delayed(Duration.zero);
      repository.calls.clear();

      //a pull re-reads the history that is on screen, with the scope it was
      //loaded under — widening one fee's payments into every payment the child
      //has made would be a different screen, not a refreshed one
      await cubit.refreshFeeTransactions(childId: 48);

      expect(repository.calls.single.feesId, 24);
      expect(repository.calls.single.page, isNull,
          reason: 'a refresh re-reads the first page');
    });
  });
}
