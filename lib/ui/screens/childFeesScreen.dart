import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/cubits/schoolSessionYearsCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/sessionYear.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/childFeeCard.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChildFeesScreen extends StatefulWidget {
  final Student child;
  ChildFeesScreen({Key? key, required this.child}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider(
      create: (_) => SchoolSessionYearsCubit(SchoolRepository()),
      child: ChildFeesScreen(child: Get.arguments as Student),
    );
  }

  @override
  State<ChildFeesScreen> createState() => _ChildFeesScreenState();
}

class _ChildFeesScreenState extends State<ChildFeesScreen>
    with WidgetsBindingObserver {
  List<SessionYear> _sessionYears = [];

  ///[Which year the filter shows as ticked]
  SessionYear? _selectedSessionYear;

  /// The only value this screen sends as `session_year_id` — first load, pull
  /// to refresh and each page alike, so they can never ask different years.
  ///
  /// Null until the year list arrives, and for good if it fails; the endpoint
  /// then answers for the school's default.
  int? _requestedSessionYearId;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_feesScrollListener);

  ///[Pulls the next page in once the list has been scrolled to its end]
  void _feesScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      context.read<ChildFeeDetailsCubit>().fetchMoreChildFeeDetails();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    //every fees request names its session year, so the year has to be known
    //first: the listener asks for the fees as soon as this lands
    _fetchSessionYears();
  }

  /// The first load, which keeps a list already in hand rather than replacing
  /// it with a spinner.
  ///
  /// [ChildFeeDetailsCubit] outlives this screen, so coming back often means
  /// the previous list is still loaded — re-read it behind the parent instead.
  /// Another child's list, or another year's, is loaded from scratch.
  void _loadChildFeeDetails() {
    final state = context.read<ChildFeeDetailsCubit>().state;
    final holdsTheSameList = state is ChildFeeDetailsFetchSuccess &&
        state.childId == (widget.child.id ?? 0) &&
        state.sessionYearId == _requestedSessionYearId;

    if (holdsTheSameList) {
      _refreshChildFeeDetails();
      return;
    }

    _fetchChildFeeDetails();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_feesScrollListener);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
  }

  void _fetchSessionYears() {
    context.read<SchoolSessionYearsCubit>().fetchSessionYears(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.child.id ?? 0,
        );
  }

  void _fetchChildFeeDetails() {
    if (mounted) {
      context.read<ChildFeeDetailsCubit>().fetchChildFeeDetails(
            childId: widget.child.id ?? 0,
            sessionYearId: _requestedSessionYearId,
          );
    }
  }

  /// Re-reads the fees without taking the ones on screen away.
  ///
  /// Awaited by the refresh indicator, so its spinner runs for as long as the
  /// request does. A failure is reported and the loaded fees left alone.
  Future<void> _refreshChildFeeDetails() async {
    final error =
        await context.read<ChildFeeDetailsCubit>().refreshChildFeeDetails(
              childId: widget.child.id ?? 0,
              sessionYearId: _requestedSessionYearId,
            );

    if (error == null || !mounted) {
      return;
    }

    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getErrorMessageFromErrorCode(context, error),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  /// Opens filter bottom sheet with same design as assignment filter.
  void _onTapFilterButton() {
    if (_sessionYears.isEmpty) return;

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      context: context,
      builder: (_) => _SessionYearFilterSheet(
        sessionYears: _sessionYears,
        selectedSessionYear: _selectedSessionYear,
        onSessionYearSelected: (sessionYear) {
          setState(() {
            _selectedSessionYear = sessionYear;
            _requestedSessionYearId = sessionYear.id;
          });
          Navigator.of(context).pop();
          _fetchChildFeeDetails();
        },
      ),
    );
  }

  /// Foot of the list while the next page loads, or when it failed.
  ///
  /// A failed page is offered as a retry rather than an error screen: the pages
  /// already loaded are still good, and replacing them with an error would lose
  /// the parent's place in the list.
  Widget _buildMoreFeesIndicator({required bool failed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Center(
        child: failed
            ? GestureDetector(
                onTap: () => context
                    .read<ChildFeeDetailsCubit>()
                    .fetchMoreChildFeeDetails(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    Utils.getTranslatedLabel(retryKey),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )
            : CustomCircularProgressIndicator(
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }

  ///[Clears the app bar, which is stacked over the scroll view]
  double get _scrollViewTopPadding => Utils.getScrollViewTopPadding(
        context: context,
        appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
      );

  /// Makes a screen with no list of its own — "no fees found", and the error
  /// page — pullable, so re-checking does not mean leaving and coming back.
  Widget _buildRefreshableMessage(Widget child) {
    return CustomRefreshIndicator(
      displacment: _scrollViewTopPadding,
      onRefreshCallback: _refreshChildFeeDetails,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          //a viewport that cannot scroll cannot be pulled
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildFeesContainer({
    required List<ChildFeeDetails> fees,
    required bool showMoreFeesIndicator,
    required bool moreFeesFetchFailed,
  }) {
    return CustomRefreshIndicator(
      displacment: _scrollViewTopPadding,
      onRefreshCallback: _refreshChildFeeDetails,
      child: ListView.builder(
        controller: _scrollController,
        //a single fee does not fill the screen, leaving nothing to pull on
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 25,
          left: Utils.screenContentHorizontalPadding,
          right: Utils.screenContentHorizontalPadding,
          top: _scrollViewTopPadding,
        ),
        //one extra row while another page is on its way, so the wait is visible
        itemCount: fees.length + (showMoreFeesIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == fees.length) {
            return _buildMoreFeesIndicator(failed: moreFeesFetchFailed);
          }
          final feeDetails = fees[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: ChildFeeCard(
              fee: feeDetails,
              onTap: () {
                Get.toNamed(
                  Routes.childFeeDetails,
                  arguments: {
                    "childFeeDetails": feeDetails,
                    "child": widget.child,
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocListener<SchoolSessionYearsCubit, SchoolSessionYearsState>(
            listener: (context, state) {
              if (state is SchoolSessionYearsFetchSuccess) {
                _sessionYears = state.sessionYears;
                final defaultIndex = _sessionYears.indexWhere(
                  (e) => e.isDefault == 1,
                );
                setState(() {
                  _selectedSessionYear = defaultIndex != -1
                      ? _sessionYears[defaultIndex]
                      : (_sessionYears.isNotEmpty ? _sessionYears.first : null);
                  _requestedSessionYearId = _selectedSessionYear?.id;
                });

                _loadChildFeeDetails();
                return;
              }

              if (state is SchoolSessionYearsFetchFailure) {
                //the fees are still readable without a year, and that beats
                //leaving the parent on a spinner because the filter's list
                //did not arrive
                _loadChildFeeDetails();
              }
            },
            child: BlocBuilder<ChildFeeDetailsCubit, ChildFeeDetailsState>(
              builder: (context, state) {
                if (state is ChildFeeDetailsFetchSuccess) {
                  if (state.fees.isEmpty) {
                    return _buildRefreshableMessage(
                      NoDataContainer(titleKey: noFeesFoundKey),
                    );
                  }
                  return _buildFeesContainer(
                    fees: state.fees,
                    //the foot shows while a page is loading, and stays as a
                    //retry when one failed
                    showMoreFeesIndicator: state.fetchMoreFeesInProgress ||
                        state.moreFeesFetchError,
                    moreFeesFetchFailed: state.moreFeesFetchError,
                  );
                }
                if (state is ChildFeeDetailsFetchFailure) {
                  return _buildRefreshableMessage(
                    ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        _fetchChildFeeDetails();
                      },
                    ),
                  );
                }
                return Center(
                  child: CustomCircularProgressIndicator(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: Utils.getTranslatedLabel(feesKey),
              onPressBackButton: () {
                Get.back();
              },
              trailingWidget: SvgButton(
                onTap: _onTapFilterButton,
                svgIconUrl: Utils.getImagePath("filter_icon.svg"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Private widget — same radio-button tile design as [AssignmentFilterBottomsheetContainer].
class _SessionYearFilterSheet extends StatefulWidget {
  final List<SessionYear> sessionYears;
  final SessionYear? selectedSessionYear;
  final Function(SessionYear) onSessionYearSelected;

  const _SessionYearFilterSheet({
    required this.sessionYears,
    required this.selectedSessionYear,
    required this.onSessionYearSelected,
  });

  @override
  State<_SessionYearFilterSheet> createState() =>
      _SessionYearFilterSheetState();
}

class _SessionYearFilterSheetState extends State<_SessionYearFilterSheet> {
  late SessionYear? _currentlySelected = widget.selectedSessionYear;

  Widget _buildFilterTile({
    required String title,
    required SessionYear sessionYear,
  }) {
    final isSelected = _currentlySelected?.id == sessionYear.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentlySelected = sessionYear;
          });
          widget.onSessionYearSelected(sessionYear);
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.75,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.075),
        vertical: MediaQuery.of(context).size.height * (0.05),
      ),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(sessionYearKey),
            style: TextStyle(
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(color: Theme.of(context).colorScheme.onSurface),
          ),
          ...widget.sessionYears.map(
            (sessionYear) => _buildFilterTile(
              title: sessionYear.name ?? '',
              sessionYear: sessionYear,
            ),
          ),
        ],
      ),
    );
  }
}
