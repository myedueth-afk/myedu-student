import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/resultTabSelectionCubit.dart';
import 'package:eschool/cubits/resultsCubit.dart';
import 'package:eschool/cubits/resultsOnlineCubit.dart';
import 'package:eschool/cubits/schoolSessionYearsCubit.dart';
import 'package:eschool/cubits/semesterCubit.dart';
import 'package:eschool/cubits/studentSubjectAndSlidersCubit.dart';

import 'package:eschool/data/models/result.dart';
import 'package:eschool/data/models/resultOnline.dart';
import 'package:eschool/data/models/semester.dart';
import 'package:eschool/data/models/sessionYear.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:eschool/data/repositories/semesterRepository.dart';

import 'package:eschool/ui/widgets/assignmentsSubjectsContainer.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/customTabBarContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/listItemForExamAndResult.dart';
import 'package:eschool/ui/widgets/listItemForOnlineExamAndOnlineResult.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/ui/widgets/tabBarBackgroundContainer.dart';

import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:get/get.dart';

class ResultsContainer extends StatefulWidget {
  final int? childId;
  final List<Subject>? subjects;

  const ResultsContainer({Key? key, this.childId, this.subjects})
      : super(key: key);

  @override
  State<ResultsContainer> createState() => _ResultsContainerState();
}

class _ResultsContainerState extends State<ResultsContainer> {
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_resultsScrollListener);

  List<SessionYear> _sessionYears = [];
  SessionYear? _selectedSessionYear;

  /// Currently applied semester. `null` when the school has no semesters
  /// configured for the selected session year (or while they are loading).
  Semester? _selectedSemester;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _fetchSessionYears();
    });
    super.initState();
  }

  void _fetchSessionYears() {
    context.read<SchoolSessionYearsCubit>().fetchSessionYears(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId ?? 0,
        );
  }

  /// Loads the semesters that belong to the currently selected session year.
  /// The results are then fetched once the semester list arrives (see the
  /// [SemesterCubit] listener in [build]).
  void _fetchSemesters() {
    final sessionYearId = _selectedSessionYear?.id;
    if (sessionYearId == null) {
      fetchResults();
      fetchOnlineResults();
      return;
    }
    context.read<SemesterCubit>().fetchSemesters(
          sessionYearId: sessionYearId,
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId,
        );
  }

  void fetchResults() {
    context.read<ResultsCubit>().fetchResults(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId,
          sessionYearId: _selectedSessionYear?.id,
          semesterId: _selectedSemester?.id,
        );
  }

  void _resultsScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<ResultTabSelectionCubit>().isResultOnline()) {
        if (context.read<ResultsOnlineCubit>().hasMore()) {
          context.read<ResultsOnlineCubit>().fetchMoreResultsOnline(
                useParentApi: context.read<AuthCubit>().isParent(),
                childId: widget.childId ?? 0,
                classSubjectId: context
                    .read<ResultTabSelectionCubit>()
                    .state
                    .resultFilterByClassSubjectId,
                sessionYearId: _selectedSessionYear?.id,
                semesterId: _selectedSemester?.id,
              );
          //to scroll to last in order for users to see the progress
          Future.delayed(const Duration(milliseconds: 10), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
            );
          });
        }
      } else {
        if (context.read<ResultsCubit>().hasMore()) {
          context.read<ResultsCubit>().fetchMoreResults(
                useParentApi: context.read<AuthCubit>().isParent(),
                childId: widget.childId,
                sessionYearId: _selectedSessionYear?.id,
                semesterId: _selectedSemester?.id,
              );
          //to scroll to last in order for users to see the progress
          Future.delayed(const Duration(milliseconds: 10), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
            );
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_resultsScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

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
      isScrollControlled: true,
      // A dedicated SemesterCubit instance is provided here so that previewing
      // a different session year's semesters inside the sheet does not disturb
      // the parent's semester state (which drives the currently shown results).
      builder: (_) => BlocProvider<SemesterCubit>(
        create: (_) => SemesterCubit(SemesterRepository()),
        child: _ResultsFilterSheet(
          sessionYears: _sessionYears,
          selectedSessionYear: _selectedSessionYear,
          selectedSemester: _selectedSemester,
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId,
          onApply: (sessionYear, semester) {
            setState(() {
              _selectedSessionYear = sessionYear;
              _selectedSemester = semester;
            });
            Navigator.of(context).pop();
            fetchResults();
            fetchOnlineResults();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(ResultTabSelectionState currentState) {
    return ScreenTopBackgroundContainer(
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              context.read<AuthCubit>().isParent()
                  ? const CustomBackButton()
                  : const SizedBox.shrink(),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    Utils.getTranslatedLabel(resultsKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: Utils.screenContentHorizontalPadding,
                  ),
                  child: SvgButton(
                    onTap: _onTapFilterButton,
                    svgIconUrl: Utils.getImagePath("filter_icon.svg"),
                  ),
                ),
              ),
              AnimatedAlign(
                curve: Utils.tabBackgroundContainerAnimationCurve,
                duration: Utils.tabBackgroundContainerAnimationDuration,
                alignment: currentState.resultFilterTabTitle == offlineKey
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child:
                    TabBarBackgroundContainer(boxConstraints: boxConstraints),
              ),
              CustomTabBarContainer(
                boxConstraints: boxConstraints,
                alignment: AlignmentDirectional.centerStart,
                isSelected: currentState.resultFilterTabTitle == offlineKey,
                onTap: () {
                  context
                      .read<ResultTabSelectionCubit>()
                      .changeResultFilterTabTitle(offlineKey);
                },
                titleKey: offlineKey,
              ),
              CustomTabBarContainer(
                boxConstraints: boxConstraints,
                alignment: AlignmentDirectional.centerEnd,
                isSelected: currentState.resultFilterTabTitle == onlineKey,
                onTap: () {
                  context
                      .read<ResultTabSelectionCubit>()
                      .changeResultFilterTabTitle(onlineKey);
                },
                titleKey: onlineKey,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultDetailsShimmerLoadingContainer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.5),
      width: MediaQuery.of(context).size.width * (0.85),
      height: 80.0,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoadingContainer(
                child: CustomShimmerContainer(
                  width: boxConstraints.maxWidth * (0.7),
                ),
              ),
              SizedBox(
                height: boxConstraints.maxHeight * (0.25),
              ),
              ShimmerLoadingContainer(
                child: CustomShimmerContainer(
                  width: boxConstraints.maxWidth * (0.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultDetailsContainer({
    required Result result,
    required int index,
    required int totalResults,
    required bool hasMoreResults,
    required bool hasMoreResultsInProgress,
    required bool fetchMoreResultsFailure,
  }) {
    return Column(
      children: [
        ListItemForExamAndResult(
          index: index,
          examStartingDate: result.examDate,
          examName: result.examName,
          resultGrade: result.grade,
          resultPercentage: result.percentage,
          onItemTap: () {
            Get.toNamed(
              Routes.result,
              arguments: {"childId": widget.childId, "result": result},
            );
          },
        ),
        if (index == (totalResults - 1) &&
            hasMoreResults &&
            hasMoreResultsInProgress)
          _buildResultDetailsShimmerLoadingContainer(),
        if (index == (totalResults - 1) &&
            hasMoreResults &&
            fetchMoreResultsFailure)
          Center(
            child: CupertinoButton(
              child: Text(Utils.getTranslatedLabel(retryKey)),
              onPressed: () {
                context.read<ResultsCubit>().fetchMoreResults(
                      useParentApi: context.read<AuthCubit>().isParent(),
                      childId: widget.childId,
                      sessionYearId: _selectedSessionYear?.id,
                      semesterId: _selectedSemester?.id,
                    );
              },
            ),
          ),
      ],
    );
  }

  Widget buildOfflineResults() {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomRefreshIndicator(
        onRefreshCallback: () {
          if (context.read<ResultsCubit>().state is ResultsFetchSuccess) {
            fetchResults();
          }
        },
        displacment: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: Utils.getScrollViewBottomPadding(context),
            top: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
            ),
          ),
          child: BlocBuilder<ResultsCubit, ResultsState>(
            builder: (context, state) {
              if (state is ResultsFetchSuccess) {
                return state.results.isNotEmpty
                    ? Column(
                        children: List.generate(
                          state.results.length,
                          (index) => index,
                        ).map((index) {
                          return _buildResultDetailsContainer(
                            result: state.results[index],
                            index: index,
                            totalResults: state.results.length,
                            hasMoreResults:
                                context.read<ResultsCubit>().hasMore(),
                            hasMoreResultsInProgress:
                                state.fetchMoreResultsInProgress,
                            fetchMoreResultsFailure:
                                state.moreResultsFetchError,
                          );
                        }).toList(),
                      )
                    : const Center(
                        child: NoDataContainer(titleKey: noResultPublishedKey),
                      );
              }
              if (state is ResultsFetchFailure) {
                return ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  onTapRetry: () {
                    fetchResults();
                  },
                );
              }
              return Column(
                children: List.generate(
                  Utils.defaultShimmerLoadingContentCount,
                  (index) => _buildResultDetailsShimmerLoadingContainer(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  //Online Result
  Widget buildMySubjectsListContainer() {
    return BlocBuilder<StudentSubjectsAndSlidersCubit,
        StudentSubjectsAndSlidersState>(
      builder: (context, state) {
        return BlocBuilder<ResultTabSelectionCubit, ResultTabSelectionState>(
          bloc: context.read<ResultTabSelectionCubit>(),
          builder: (context, state) {
            return AssignmentsSubjectContainer(
              cubitAndState: "onlineResult",
              onTapSubject: (classSubjectId) {
                //fetch student online Result according to respected subjectId
                context
                    .read<ResultTabSelectionCubit>()
                    .changeResultFilterBySubjectId(classSubjectId);
                fetchOnlineResults();
              },
              selectedClassSubjectId: state.resultFilterByClassSubjectId,
              subjects: (widget.subjects != null)
                  ? widget.subjects! //from parent
                  : context
                      .read<StudentSubjectsAndSlidersCubit>()
                      .getSubjectsForAssignmentContainer(),
            );
          },
        );
      },
    );
  }

  void fetchOnlineResults() {
    context.read<ResultsOnlineCubit>().fetchResultsOnline(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId ?? 0,
          classSubjectId: context
              .read<ResultTabSelectionCubit>()
              .state
              .resultFilterByClassSubjectId,
          sessionYearId: _selectedSessionYear?.id,
          semesterId: _selectedSemester?.id,
        );
  }

  Widget _buildOnlineResultDetailsContainer({
    required ResultOnline result,
    required int index,
    required int totalResults,
    required bool hasMoreResults,
    required bool hasMoreResultsInProgress,
    required bool fetchMoreResultsFailure,
  }) {
    if (index == (totalResults - 1)) {
      if (hasMoreResults) {
        if (hasMoreResultsInProgress) {
          return _buildResultDetailsShimmerLoadingContainer(); //same for both Online and Offline Result
        }
        if (fetchMoreResultsFailure) {
          return Center(
            child: CupertinoButton(
              child: Text(Utils.getTranslatedLabel(retryKey)),
              onPressed: () {
                context.read<ResultsOnlineCubit>().fetchMoreResultsOnline(
                      useParentApi: context.read<AuthCubit>().isParent(),
                      childId: widget.childId ?? 0,
                      classSubjectId: context
                          .read<ResultTabSelectionCubit>()
                          .state
                          .resultFilterByClassSubjectId,
                      sessionYearId: _selectedSessionYear?.id,
                      semesterId: _selectedSemester?.id,
                    );
              },
            ),
          );
        }
      }
    }
    return ListItemForOnlineExamAndOnlineResult(
      isExamStarted: true,
      examStartingDate: result.examDate,
      examEndingDate: result.examDate,
      examName: result.examName,
      subjectName: result.subject.getSubjectName(context: context),
      totalMarks: result.totalMarks,
      marks: result.obtainedMarks,
      isSubjectSelected: (context
                  .read<ResultTabSelectionCubit>()
                  .state
                  .resultFilterByClassSubjectId !=
              0)
          ? true
          : false,
      onItemTap: () {
        Get.toNamed(
          Routes.resultOnline,
          arguments: {
            "examId": result.examId,
            "examName": result.examName,
            "subjectName": result.subject.getSubjectName(context: context),
            "childId": widget.childId,
          },
        );
      },
    );
  }

  Widget buildOnlineResults() {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomRefreshIndicator(
        onRefreshCallback: () {
          if (context.read<ResultsOnlineCubit>().state
              is ResultsOnlineFetchSuccess) {
            fetchOnlineResults();
          }
        },
        displacment: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: Utils.getScrollViewBottomPadding(context),
            top: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
            ),
          ),
          child: Column(
            children: [
              buildMySubjectsListContainer(),
              SizedBox(
                height: MediaQuery.of(context).size.height * (0.035),
              ),
              BlocBuilder<ResultsOnlineCubit, ResultsOnlineState>(
                builder: (context, state) {
                  if (state is ResultsOnlineFetchSuccess) {
                    return state.results.isNotEmpty
                        ? Column(
                            children: List.generate(
                              state.results.length,
                              (index) => index,
                            ).map((index) {
                              return _buildOnlineResultDetailsContainer(
                                result: state.results[index],
                                index: index,
                                totalResults: state.results.length,
                                hasMoreResults: context
                                    .read<ResultsOnlineCubit>()
                                    .hasMore(),
                                hasMoreResultsInProgress:
                                    state.fetchMoreResultsOnlineInProgress,
                                fetchMoreResultsFailure:
                                    state.moreResultsOnlineFetchError,
                              );
                            }).toList(),
                          )
                        : const Center(
                            child: NoDataContainer(
                              titleKey: noResultPublishedKey,
                            ),
                          );
                  }
                  if (state is ResultsOnlineFetchFailure) {
                    return ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        fetchOnlineResults();
                      },
                    );
                  }
                  return Column(
                    children: List.generate(
                      Utils.defaultShimmerLoadingContentCount,
                      (index) => _buildResultDetailsShimmerLoadingContainer(),
                    ),
                    //same for both Online and Offline Result
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SchoolSessionYearsCubit, SchoolSessionYearsState>(
          listener: (context, sessionState) {
            if (sessionState is SchoolSessionYearsFetchSuccess) {
              _sessionYears = sessionState.sessionYears;
              final defaultIndex =
                  _sessionYears.indexWhere((e) => e.isDefault == 1);
              _selectedSessionYear = defaultIndex != -1
                  ? _sessionYears[defaultIndex]
                  : (_sessionYears.isNotEmpty ? _sessionYears.first : null);
              setState(() {});
              // Load this session year's semesters first; the results fetch is
              // triggered once they arrive (or fail) by the listener below.
              _fetchSemesters();
            }
          },
        ),
        BlocListener<SemesterCubit, SemesterState>(
          listener: (context, semesterState) {
            if (semesterState is SemesterFetchSuccess) {
              _selectedSemester = _defaultSemesterFrom(semesterState.semesters);
              setState(() {});
              fetchResults();
              fetchOnlineResults();
            } else if (semesterState is SemesterFetchFailure) {
              // Fall back to fetching results without a semester filter so the
              // screen still works for schools/backends without semesters.
              _selectedSemester = null;
              fetchResults();
              fetchOnlineResults();
            }
          },
        ),
      ],
      child: BlocBuilder<ResultTabSelectionCubit, ResultTabSelectionState>(
        builder: (context, state) {
          return Stack(
            children: [
              (context.read<ResultTabSelectionCubit>().isResultOnline())
                  ? buildOnlineResults()
                  : buildOfflineResults(),
              Align(
                alignment: Alignment.topCenter,
                child: _buildAppBar(state),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Picks the semester to select by default from a list: the one flagged as
/// [Semester.current], otherwise the first one, otherwise `null` (no semesters).
Semester? _defaultSemesterFrom(List<Semester> semesters) {
  if (semesters.isEmpty) return null;
  return semesters.firstWhere(
    (semester) => semester.current == true,
    orElse: () => semesters.first,
  );
}

/// Combined Session Year + Semester filter bottom sheet for the results screen.
///
/// Semesters are scoped to a session year, so changing the session year here
/// re-fetches the semesters for that year via the (locally scoped)
/// [SemesterCubit]. Nothing is applied to the results until [onApply] is
/// invoked through the Apply button.
class _ResultsFilterSheet extends StatefulWidget {
  final List<SessionYear> sessionYears;
  final SessionYear? selectedSessionYear;
  final Semester? selectedSemester;
  final bool useParentApi;
  final int? childId;
  final void Function(SessionYear sessionYear, Semester? semester) onApply;

  const _ResultsFilterSheet({
    required this.sessionYears,
    required this.selectedSessionYear,
    required this.selectedSemester,
    required this.useParentApi,
    required this.childId,
    required this.onApply,
  });

  @override
  State<_ResultsFilterSheet> createState() => _ResultsFilterSheetState();
}

class _ResultsFilterSheetState extends State<_ResultsFilterSheet> {
  late SessionYear? _pendingSessionYear = widget.selectedSessionYear;
  late Semester? _pendingSemester = widget.selectedSemester;

  @override
  void initState() {
    super.initState();
    // Load the semesters for the initially selected session year so the
    // semester section is populated as soon as the sheet opens.
    Future.delayed(Duration.zero, () {
      final sessionYearId = _pendingSessionYear?.id;
      if (sessionYearId != null) {
        context.read<SemesterCubit>().fetchSemesters(
              sessionYearId: sessionYearId,
              useParentApi: widget.useParentApi,
              childId: widget.childId,
            );
      }
    });
  }

  void _onSessionYearTap(SessionYear sessionYear) {
    if (_pendingSessionYear?.id == sessionYear.id) return;
    setState(() {
      _pendingSessionYear = sessionYear;
      // The previous semester belongs to the previous session year; reset it
      // so the default semester of the newly selected year gets applied.
      _pendingSemester = null;
    });
    final sessionYearId = sessionYear.id;
    if (sessionYearId != null) {
      context.read<SemesterCubit>().fetchSemesters(
            sessionYearId: sessionYearId,
            useParentApi: widget.useParentApi,
            childId: widget.childId,
          );
    }
  }

  Widget _buildRadioTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A grouped, rounded card matching the reference design: a bold section
  /// title followed by its options.
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSemesterSection() {
    return BlocConsumer<SemesterCubit, SemesterState>(
      listener: (context, state) {
        if (state is SemesterFetchSuccess) {
          final stillValid = _pendingSemester != null &&
              state.semesters.any((s) => s.id == _pendingSemester!.id);
          if (!stillValid) {
            setState(() {
              _pendingSemester = _defaultSemesterFrom(state.semesters);
            });
          }
        }
      },
      builder: (context, state) {
        if (state is SemesterFetchInProgress || state is SemesterInitial) {
          return _buildSectionCard(
            title: Utils.getTranslatedLabel(semesterKey),
            children: List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 14,
                  ),
                ),
              ),
            ),
          );
        }
        if (state is SemesterFetchSuccess && state.semesters.isNotEmpty) {
          return _buildSectionCard(
            title: Utils.getTranslatedLabel(semesterKey),
            children: state.semesters
                .map(
                  (semester) => _buildRadioTile(
                    title: semester.name ?? '',
                    isSelected: _pendingSemester?.id == semester.id,
                    onTap: () {
                      setState(() {
                        _pendingSemester = semester;
                      });
                    },
                  ),
                )
                .toList(),
          );
        }
        // No semesters for this session year (or a fetch failure) → hide the
        // section entirely so only the Session Year filter is shown.
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * (0.06),
        right: MediaQuery.of(context).size.width * (0.06),
        top: MediaQuery.of(context).size.height * (0.03),
        bottom: MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).size.height * (0.03),
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
            Utils.getTranslatedLabel(filterKey),
            style: TextStyle(
              fontSize: 18.0,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: Utils.getTranslatedLabel(sessionYearKey),
                    children: widget.sessionYears
                        .map(
                          (sessionYear) => _buildRadioTile(
                            title: sessionYear.name ?? '',
                            isSelected:
                                _pendingSessionYear?.id == sessionYear.id,
                            onTap: () => _onSessionYearTap(sessionYear),
                          ),
                        )
                        .toList(),
                  ),
                  _buildSemesterSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _pendingSessionYear == null
                  ? null
                  : () =>
                      widget.onApply(_pendingSessionYear!, _pendingSemester),
              child: Text(
                Utils.getTranslatedLabel(applyKey),
                style: TextStyle(
                  fontSize: 15.0,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
