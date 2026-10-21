import 'dart:async';

import 'package:eschool/cubits/childFeeCubit.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fee screens used to show whatever was fetched when first reached and
/// never ask again. These cover the reads that replaced that, and the promise a
/// pull to refresh has to keep: never take away what is on screen.

/// The paginator `parent/fees` returns, trimmed to the fields the app reads.
Map<String, dynamic> _paginator({
  required List<Map<String, dynamic>> fees,
  required int currentPage,
  required int lastPage,
}) =>
    {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': 10,
      'total': fees.length,
      'data': fees,
    };

Map<String, dynamic> _fee(int id, {String status = 'Unpaid'}) =>
    {'id': id, 'name': 'Fee $id', 'status': status};

class _FakeFeeRepository extends FeeRepository {
  /// Fees per page, keyed by page number.
  final Map<int, List<Map<String, dynamic>>> pages;
  final int lastPage;

  /// Every page the cubit asked for, in order — null is "no page parameter".
  final List<int?> requestedPages = [];
  final List<int?> requestedSessionYears = [];

  Object? errorToThrow;

  _FakeFeeRepository({required this.pages, this.lastPage = 1});

  @override
  Future<Map<String, dynamic>> fetchChildFeeDetails({
    required int childId,
    int? sessionYearId,
    int? page,
  }) async {
    requestedPages.add(page);
    requestedSessionYears.add(sessionYearId);

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    return FeeRepository.parseFeesPage(
      _paginator(
        fees: pages[page ?? 1] ?? const [],
        currentPage: page ?? 1,
        lastPage: lastPage,
      ),
    );
  }
}

/// Serves one fee back, or fails, without going near the paging walk.
class _SingleFeeRepository extends FeeRepository {
  ChildFeeDetails? fee;
  Object? errorToThrow;
  int calls = 0;

  /// Held open so a second call can be attempted while the first is in flight.
  Completer<void>? gate;

  @override
  Future<ChildFeeDetails?> fetchChildFee({
    required int childId,
    required int feeId,
    int? sessionYearId,
  }) async {
    calls++;
    if (gate != null) {
      await gate!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return fee;
  }
}

void main() {
  group('reading one fee back', () {
    test('finds it on the first page in a single request', () async {
      //the common case: the child's fees fit one page. Nothing should page on
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30), _fee(31)],
      });

      final fee = await repository.fetchChildFee(childId: 262, feeId: 31);

      expect(fee?.id, 31);
      expect(repository.requestedPages, [null],
          reason: 'the first page is asked for the way the list asks for it');
    });

    test('walks on to later pages when it is not on the first', () async {
      final repository = _FakeFeeRepository(
        pages: {
          1: [_fee(30)],
          2: [_fee(31)],
          3: [_fee(32)],
        },
        lastPage: 3,
      );

      final fee = await repository.fetchChildFee(childId: 262, feeId: 32);

      expect(fee?.id, 32);
      expect(repository.requestedPages, [null, 2, 3]);
    });

    test('gives up rather than guessing when the fee is gone', () async {
      //deleted, or moved to another year; the caller keeps the copy it has
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });

      expect(await repository.fetchChildFee(childId: 262, feeId: 99), isNull);
    });

    test('stops paging even when the server reports a nonsense page count',
        () async {
      //a wrong last_page would otherwise mean endless requests
      final repository = _FakeFeeRepository(pages: {}, lastPage: 100000);

      expect(await repository.fetchChildFee(childId: 262, feeId: 99), isNull);
      expect(repository.requestedPages.length, lessThanOrEqualTo(20));
    });
  });

  group('the fee details screen re-reading its own fee', () {
    late _SingleFeeRepository repository;
    late ChildFeeCubit cubit;

    setUp(() {
      repository = _SingleFeeRepository();
      cubit = ChildFeeCubit(
        repository,
        fee: ChildFeeDetails.fromJson(_fee(30)),
        childId: 262,
      );
    });

    test('starts from the copy the list handed over', () {
      //so the screen draws at once rather than spinning over data it has
      expect(cubit.state.fee.id, 30);
      expect(cubit.state.refreshInProgress, isFalse);
    });

    test('puts what came back on screen', () async {
      repository.fee = ChildFeeDetails.fromJson(_fee(30, status: 'Success'));

      await cubit.refresh();

      expect(cubit.state.fee.status, 'Success');
      expect(cubit.state.refreshError, isNull);
    });

    test('keeps the fee and reports the failure when the read fails', () async {
      repository.errorToThrow = 'no-internet';

      await cubit.refresh();

      expect(cubit.state.fee.id, 30, reason: 'still the last good copy');
      expect(cubit.state.refreshError, contains('no-internet'));
    });

    test('keeps the fee when it is no longer in the list', () async {
      repository.fee = null;

      await cubit.refresh();

      expect(cubit.state.fee.id, 30);
      expect(cubit.state.refreshError, isNull);
    });

    test('drops a second read while the first is still running', () async {
      //opening and pulling can land within a frame of each other
      repository.gate = Completer<void>();
      final first = cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      await cubit.refresh();
      repository.gate!.complete();
      await first;

      expect(repository.calls, 1);
    });

    test('a fresh read clears the failure before it', () async {
      repository.errorToThrow = 'no-internet';
      await cubit.refresh();
      expect(cubit.state.refreshError, isNotNull);

      repository.errorToThrow = null;
      repository.fee = ChildFeeDetails.fromJson(_fee(30, status: 'Success'));
      await cubit.refresh();

      expect(cubit.state.refreshError, isNull);
    });
  });

  group('pulling to refresh the fee list', () {
    test('never puts a spinner where the fees were', () async {
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30), _fee(31)],
      });
      final cubit = ChildFeeDetailsCubit(repository);

      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);

      final states = <ChildFeeDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.refreshChildFeeDetails(childId: 262);
      await subscription.cancel();

      //the loading state would replace the list being pulled on
      expect(states.whereType<ChildFeeDetailsFetchInProgress>(), isEmpty);
      expect((cubit.state as ChildFeeDetailsFetchSuccess).fees.length, 2);
    });

    test('brings back what changed', () async {
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);
      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);

      repository.pages[1] = [_fee(30, status: 'Success'), _fee(31)];
      final error = await cubit.refreshChildFeeDetails(childId: 262);

      expect(error, isNull);
      final fees = (cubit.state as ChildFeeDetailsFetchSuccess).fees;
      expect(fees.length, 2);
      expect(fees.first.status, 'Success');
    });

    test('keeps the fees and hands back the failure', () async {
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);
      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);

      repository.errorToThrow = 'no-internet';
      final error = await cubit.refreshChildFeeDetails(childId: 262);

      expect(error, contains('no-internet'));
      //a dropped connection is no reason to take away fees that were true a
      //moment ago
      expect((cubit.state as ChildFeeDetailsFetchSuccess).fees.length, 1);
    });

    test('loads from scratch when there is nothing on screen yet', () async {
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);

      await cubit.refreshChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<ChildFeeDetailsFetchSuccess>());
    });

    test('asks for exactly the list on screen, not what the screen thinks now',
        () async {
      //The screen sends `session_year_id` on every fees request, and the pull
      //has to send the same one the load did. Driving it off the filter's tick
      //instead is what broke that once already: the tick is populated from a
      //separate request, so the two could name different years and a pull
      //could swap the list to one the parent never picked.
      //
      //A caller that has drifted is ignored — the refresh re-reads the list
      //that is actually on screen.
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);

      cubit.fetchChildFeeDetails(childId: 262, sessionYearId: 1);
      await Future<void>.delayed(Duration.zero);

      repository.requestedSessionYears.clear();
      await cubit.refreshChildFeeDetails(childId: 262, sessionYearId: 7);

      expect(repository.requestedSessionYears, [1]);
    });

    test('names no year when the load could not name one either', () async {
      //the year list failed, so the fees were read without it and the school's
      //default answered. The pull has to ask the same way, or it would quietly
      //move the parent to a different year
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);

      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);

      repository.requestedSessionYears.clear();
      await cubit.refreshChildFeeDetails(childId: 262, sessionYearId: 1);

      expect(repository.requestedSessionYears, [null]);
    });

    test('follows the filter once the parent has chosen a year', () async {
      final repository = _FakeFeeRepository(pages: {
        1: [_fee(30)],
      });
      final cubit = ChildFeeDetailsCubit(repository);

      //picking a year in the filter is a full load, and it is that list the
      //pull then re-reads — the year travels with the list, not the gesture
      cubit.fetchChildFeeDetails(childId: 262, sessionYearId: 7);
      await Future<void>.delayed(Duration.zero);

      repository.requestedSessionYears.clear();
      await cubit.refreshChildFeeDetails(childId: 262);

      expect(repository.requestedSessionYears, [7]);
    });

    test('asks only for the first page, not for every page already loaded',
        () async {
      final repository = _FakeFeeRepository(
        pages: {
          1: [_fee(30)],
          2: [_fee(31)],
        },
        lastPage: 2,
      );
      final cubit = ChildFeeDetailsCubit(repository);
      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);
      await cubit.fetchMoreChildFeeDetails();

      repository.requestedPages.clear();
      await cubit.refreshChildFeeDetails(childId: 262);

      expect(repository.requestedPages, [null]);
    });
  });

  group('one fee changing behind the list', () {
    late ChildFeeDetailsCubit cubit;

    setUp(() async {
      cubit = ChildFeeDetailsCubit(_FakeFeeRepository(pages: {
        1: [_fee(30), _fee(31)],
      }));
      cubit.fetchChildFeeDetails(childId: 262);
      await Future<void>.delayed(Duration.zero);
    });

    test('replaces just that fee, leaving the rest of the list alone', () {
      //what the details screen learned on opening, carried back to the card
      //the parent returns to
      cubit.updateFee(ChildFeeDetails.fromJson(_fee(31, status: 'Success')));

      final fees = (cubit.state as ChildFeeDetailsFetchSuccess).fees;
      expect(fees.length, 2);
      expect(fees[0].status, 'Unpaid');
      expect(fees[1].status, 'Success');
    });

    test('ignores a fee the list has never heard of', () {
      cubit.updateFee(ChildFeeDetails.fromJson(_fee(99)));

      expect((cubit.state as ChildFeeDetailsFetchSuccess).fees.length, 2);
    });
  });

  group('the refresh indicator', () {
    testWidgets('holds its spinner for as long as the request runs',
        (tester) async {
      //it used to fire and forget, so the spinner snapped away the moment the
      //pull was released — reading as "done" while the screen was still waiting
      final finished = Completer<void>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomRefreshIndicator(
            displacment: 0,
            onRefreshCallback: () => finished.future,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 40, child: Text('a fee'))],
            ),
          ),
        ),
      ));

      await tester.fling(find.text('a fee'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      finished.complete();
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('lays out where the fee details screen puts it',
        (tester) async {
      //that screen stacks its app bar over the scroll view, so the refreshable
      //part sits inside an Align inside a Stack. A scroll view needs a bounded
      //height, and this is the arrangement that has to give it one
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: CustomRefreshIndicator(
                  displacment: 100,
                  onRefreshCallback: () async {},
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: const Text('fee breakdown'),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(height: 100, color: Colors.blue),
              ),
            ],
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('fee breakdown'), findsOneWidget);
    });
  });
}
