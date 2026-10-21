import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paginator `parent/fees` actually returns, trimmed to the fields the app
/// reads.
Map<String, dynamic> _paginator({
  required List<int> ids,
  required int currentPage,
  required int lastPage,
}) {
  return {
    'current_page': currentPage,
    'last_page': lastPage,
    'per_page': 10,
    'total': 11,
    'data': ids.map((id) => {'id': id, 'name': 'Fee'}).toList(),
  };
}

class _FakeFeeRepository extends FeeRepository {
  final Map<int, List<int>> pages;
  final int lastPage;
  Object? errorOnPage2;
  final List<int?> requestedPages = [];

  _FakeFeeRepository({required this.pages, required this.lastPage});

  @override
  Future<Map<String, dynamic>> fetchChildFeeDetails({
    required int childId,
    int? sessionYearId,
    int? page,
  }) async {
    requestedPages.add(page);
    final requested = page ?? 1;

    if (requested == 2 && errorOnPage2 != null) {
      throw errorOnPage2!;
    }

    return FeeRepository.parseFeesPage(
      _paginator(
        ids: pages[requested] ?? [],
        currentPage: requested,
        lastPage: lastPage,
      ),
    );
  }
}

void main() {
  group('FeeRepository.parseFeesPage', () {
    test('reads the paginator the endpoint returns', () {
      final result = FeeRepository.parseFeesPage(
        _paginator(ids: [24, 23, 22], currentPage: 1, lastPage: 2),
      );

      expect((result['fees'] as List<ChildFeeDetails>).length, 3);
      expect(result['currentPage'], 1);
      expect(result['totalPage'], 2);
    });

    test('still reads a bare list, which is what the endpoint used to send',
        () {
      //casting this shape straight to a paginator (or the reverse) is what
      //broke the fee list
      final result = FeeRepository.parseFeesPage([
        {'id': 24},
        {'id': 23},
      ]);

      expect((result['fees'] as List<ChildFeeDetails>).length, 2);
      expect(result['currentPage'], 1);
      expect(result['totalPage'], 1, reason: 'a bare list is a single page');
    });

    test('treats a missing payload as an empty first page', () {
      final result = FeeRepository.parseFeesPage(null);

      expect(result['fees'], isEmpty);
      expect(result['currentPage'], 1);
      expect(result['totalPage'], 1);
    });
  });

  group('ChildFeeDetailsCubit paging', () {
    late _FakeFeeRepository repository;
    late ChildFeeDetailsCubit cubit;

    setUp(() {
      repository = _FakeFeeRepository(
        pages: {
          1: [24, 23, 22, 21, 20, 19, 18, 17, 16, 14],
          2: [13],
        },
        lastPage: 2,
      );
      cubit = ChildFeeDetailsCubit(repository);
    });

    Future<void> loadFirstPage() async {
      cubit.fetchChildFeeDetails(childId: 48, sessionYearId: 1);
      await Future<void>.delayed(Duration.zero);
    }

    test('loads the first page and knows another one exists', () async {
      await loadFirstPage();

      final state = cubit.state as ChildFeeDetailsFetchSuccess;
      expect(state.fees.length, 10);
      expect(state.currentPage, 1);
      expect(state.totalPage, 2);
      expect(cubit.hasMore(), isTrue);
      //the first request must not ask for a page, so the endpoint's own
      //default applies
      expect(repository.requestedPages, [null]);
    });

    test('appends the next page instead of replacing what is shown', () async {
      await loadFirstPage();
      await cubit.fetchMoreChildFeeDetails();

      final state = cubit.state as ChildFeeDetailsFetchSuccess;
      expect(state.fees.length, 11, reason: '10 already shown plus 1 more');
      expect(state.currentPage, 2);
      expect(cubit.hasMore(), isFalse, reason: 'the last page was reached');
      expect(repository.requestedPages, [null, 2]);
    });

    test('does not ask for the last page again once it is loaded', () async {
      await loadFirstPage();
      await cubit.fetchMoreChildFeeDetails();
      await cubit.fetchMoreChildFeeDetails();

      expect(repository.requestedPages, [null, 2]);
      expect((cubit.state as ChildFeeDetailsFetchSuccess).fees.length, 11);
    });

    test('keeps the loaded fees when the next page fails, and can retry',
        () async {
      repository.errorOnPage2 = ApiException('no internet');
      await loadFirstPage();
      await cubit.fetchMoreChildFeeDetails();

      var state = cubit.state as ChildFeeDetailsFetchSuccess;
      //the parent keeps their place in the list rather than losing it to an
      //error screen
      expect(state.fees.length, 10);
      expect(state.moreFeesFetchError, isTrue);
      expect(state.fetchMoreFeesInProgress, isFalse);

      repository.errorOnPage2 = null;
      await cubit.fetchMoreChildFeeDetails();

      state = cubit.state as ChildFeeDetailsFetchSuccess;
      expect(state.fees.length, 11);
      expect(state.moreFeesFetchError, isFalse);
    });

    test('a single page offers nothing more to load', () async {
      cubit = ChildFeeDetailsCubit(
        _FakeFeeRepository(pages: {
          1: [24]
        }, lastPage: 1),
      );
      await loadFirstPage();

      expect(cubit.hasMore(), isFalse);
      await cubit.fetchMoreChildFeeDetails();
      expect((cubit.state as ChildFeeDetailsFetchSuccess).fees.length, 1);
    });
  });
}
