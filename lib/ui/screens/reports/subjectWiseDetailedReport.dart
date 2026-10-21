import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/resultTabSelectionCubit.dart';
import 'package:eschool/cubits/studentProfileCubit.dart';
import 'package:eschool/cubits/subjectWiseReportCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/ui/screens/reports/widgets/assignmentReportCard.dart';
import 'package:eschool/ui/screens/reports/widgets/diaryReportCard.dart';
import 'package:eschool/ui/screens/reports/widgets/offlineExamReportCard.dart';
import 'package:eschool/ui/screens/reports/widgets/onlineExamReportCard.dart';
import 'package:eschool/ui/screens/reports/widgets/subjectSelectorDropdown.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:get/get.dart';

class SubjectWiseDetailedReport extends StatefulWidget {
  final Subject subject;
  final int? childId;

  /// Full list of subjects for the in-screen dropdown.
  /// When null or contains only one entry the dropdown is hidden.
  final List<Subject>? subjects;

  const SubjectWiseDetailedReport({
    Key? key,
    required this.subject,
    this.childId,
    this.subjects,
  }) : super(key: key);

  @override
  SubjectWiseDetailedReportState createState() =>
      SubjectWiseDetailedReportState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return SubjectWiseDetailedReport(
      subject: arguments['subject'],
      childId: arguments['childId'] ?? 0,
      subjects: arguments['subjects'] as List<Subject>?,
    );
  }
}

class SubjectWiseDetailedReportState extends State<SubjectWiseDetailedReport> {
  late Subject _selectedSubject;

  bool get _hasDropdown =>
      widget.subjects != null && widget.subjects!.length > 1;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.subject;
    Future.delayed(Duration.zero, fetchReportData);
  }

  void fetchReportData() {
    context.read<SubjectWiseReportCubit>().fetchSubjectWiseReport(
          classSubjectId: _selectedSubject.classSubjectId ?? 0,
          childId: widget.childId ?? 0,
          useParentApi: context.read<AuthCubit>().isParent(),
        );
  }

  /// Navigates to the StudentDiaryScreen.
  /// - Parent  → studentId is the child's user_id, id is childId
  /// - Student → reads own profile id from StudentProfileCubit
  void _navigateToDiary() {
    final isParent = context.read<AuthCubit>().isParent();
    if (isParent) {
      final int childId = widget.childId ?? 0;
      final child = AuthRepository.getParentDetails()
          .children
          ?.firstWhereOrNull((child) => child.id == childId);
      Get.toNamed(
        Routes.studentDiaryScreen,
        arguments: {'studentId': child?.userId ?? 0, 'id': childId},
      );
      return;
    }
    final int studentId =
        context.read<StudentProfileCubit>().getCurrentStudentProfile().id ?? 0;
    Get.toNamed(
      Routes.studentDiaryScreen,
      arguments: {'studentId': studentId, 'id': studentId},
    );
  }

  /// Navigates to the exam results screen and pre-selects the given tab.
  /// - Parent  → ChildResultsScreen (childId + subjects list)
  /// - Student → StudentResultsScreen (standalone, fetches own results)
  /// Tab pre-selection works because ResultTabSelectionCubit is global (app.dart).
  void _navigateToExamResult({required bool isOnline}) {
    context
        .read<ResultTabSelectionCubit>()
        .changeResultFilterTabTitle(isOnline ? onlineKey : offlineKey);

    if (context.read<AuthCubit>().isParent()) {
      Get.toNamed(
        Routes.childResults,
        arguments: {
          'childId': widget.childId ?? 0,
          'subjects': widget.subjects ?? [widget.subject],
        },
      );
    } else {
      Get.toNamed(Routes.studentResults);
    }
  }

  /// Navigates to the assignments screen.
  /// Both parent and student use ChildAssignmentsScreen — it calls
  /// useParentApi: isParent() internally, so student API is used automatically.
  /// For students childId is 0 (ignored by the student API endpoint).
  void _navigateToAssignments() {
    Get.toNamed(
      Routes.childAssignments,
      arguments: {
        'childId': widget.childId ?? 0,
        'subjects': widget.subjects ?? [widget.subject],
        // Pre-select the subject currently viewed in the report.
        'initialClassSubjectId': _selectedSubject.classSubjectId ?? 0,
      },
    );
  }

  void _onSubjectChanged(Subject subject) {
    setState(() => _selectedSubject = subject);
    context.read<SubjectWiseReportCubit>().fetchSubjectWiseReport(
          classSubjectId: subject.classSubjectId ?? 0,
          childId: widget.childId ?? 0,
          useParentApi: context.read<AuthCubit>().isParent(),
        );
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      padding: EdgeInsets.zero,
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Stack(
        children: [
          CustomBackButton(
            topPadding: MediaQuery.of(context).padding.top +
                Utils.appBarContentTopPadding,
          ),
          Align(
            child: Text(
              _hasDropdown
                  ? Utils.getTranslatedLabel(reportsKey)
                  : _selectedSubject.getSubjectName(context: context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SubjectWiseReportCubit, SubjectWiseReportState>(
      builder: (context, state) {
        if (state is SubjectWiseReportFetchSuccess) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasDropdown) ...[
                  SubjectSelectorDropdown(
                    subjects: widget.subjects!,
                    selectedSubject: _selectedSubject,
                    onChanged: _onSubjectChanged,
                  ),
                  const SizedBox(height: 24),
                ],
                AssignmentReportCard(
                  report: state.report.assignmentReport,
                  onViewAssignment: _navigateToAssignments,
                ),
                DiaryReportCard(
                  report: state.report.diaryReport,
                  onViewDiary: _navigateToDiary,
                ),
                OnlineExamReportCard(
                  report: state.report.onlineExamReport,
                  onViewExamResult: () => _navigateToExamResult(isOnline: true),
                ),
                OfflineExamReportCard(
                  report: state.report.offlineExamReport,
                  subject: _selectedSubject,
                  onViewExamResult: () =>
                      _navigateToExamResult(isOnline: false),
                ),
              ],
            ),
          );
        }

        if (state is SubjectWiseReportFetchFailure) {
          return Padding(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
              left: 16,
              right: 16,
            ),
            child: Column(
              children: [
                if (_hasDropdown) ...[
                  SubjectSelectorDropdown(
                    subjects: widget.subjects!,
                    selectedSubject: _selectedSubject,
                    onChanged: _onSubjectChanged,
                  ),
                  const SizedBox(height: 24),
                ],
                Align(
                  alignment: Alignment.topCenter,
                  child: state.errorMessage ==
                          ErrorMessageKeysAndCode.noDataFoundCode
                      ? NoDataContainer(
                          titleKey: ErrorMessageKeysAndCode
                              .getErrorMessageKeyFromCode(
                            state.errorMessage,
                          ),
                        )
                      : ErrorContainer(
                          errorMessageCode: state.errorMessage,
                          onTapRetry: fetchReportData,
                        ),
                ),
              ],
            ),
          );
        }

        // Loading state — still show dropdown so user isn't left staring at
        // a blank screen with no context.
        return Stack(
          children: [
            if (_hasDropdown)
              Padding(
                padding: EdgeInsets.only(
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                  ),
                  left: 16,
                  right: 16,
                ),
                child: SubjectSelectorDropdown(
                  subjects: widget.subjects!,
                  selectedSubject: _selectedSubject,
                  onChanged: _onSubjectChanged,
                ),
              ),
            Center(
              child: CustomCircularProgressIndicator(
                indicatorColor: Utils.getColorScheme(context).primary,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          Align(
            alignment: Alignment.topCenter,
            child: _buildAppBar(),
          ),
        ],
      ),
    );
  }
}
