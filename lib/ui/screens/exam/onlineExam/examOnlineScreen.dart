import 'dart:async';
import 'dart:io';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/examTabSelectionCubit.dart';
import 'package:eschool/cubits/examsOnlineCubit.dart';
import 'package:eschool/cubits/submitOnlineExamAnswersCubit.dart';
import 'package:eschool/data/models/answerOption.dart';
import 'package:eschool/data/models/question.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';
import 'package:eschool/data/repositories/pendingExamSubmissionRepository.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/screenProtectorWrapper.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';

import 'package:eschool/cubits/onlineExamQuestionsCubit.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examQuestionStatusBottomSheetContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examTimerContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/optionContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/questionContainer.dart';

import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';

import 'package:eschool/data/models/examOnline.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ExamOnlineScreen extends StatefulWidget {
  final ExamOnline exam;
  const ExamOnlineScreen({Key? key, required this.exam}) : super(key: key);

  @override
  ExamOnlineScreenState createState() => ExamOnlineScreenState();
  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return ScreenProtectorWrapper(
      child: BlocProvider(
        create: (context) =>
            SubmitOnlineExamAnswersCubit(OnlineExamRepository()),
        child: ExamOnlineScreen(
          exam: arguments['exam'],
        ),
      ),
    );
  }
}

class ExamOnlineScreenState extends State<ExamOnlineScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ExamTimerContainerState> timerKey =
      GlobalKey<ExamTimerContainerState>();
  late PageController pageController = PageController();

  bool isExitDialogOpen = false;
  bool isExamQuestionStatusBottomsheetOpen = false;
  bool isExamCompleted = false;
  bool isSubmissionInProgress = false;
  bool isExitTriggeredSubmission = false;

  // Offline submission retry variables
  bool _hasPendingSubmission = false;
  Timer? _connectivityCheckTimer;
  bool _isWaitingForConnection = false;

  // Track if user went to background (for auto-submit on return)
  bool _hasGoneToBackground = false;
  bool _isAutoSubmittingOnResume = false;

  int currentQuestionIndex = 0;
  Map<int, List<int>> _selectedAnswersWithQuestionId = {};

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      timerKey.currentState?.startTimer();

      // Save exam state to Hive for app termination handling
      _savePendingExamState();
    });

    WakelockPlus.enable();

    WidgetsBinding.instance.addObserver(this);
  }

  /// Save current exam state to Hive for handling app termination
  Future<void> _savePendingExamState() async {
    await PendingExamSubmissionRepository.savePendingExam(
      examId: widget.exam.id ?? 0,
      answers: _selectedAnswersWithQuestionId,
      examTitle: widget.exam.title ?? '',
      subjectName: widget.exam.subject?.getSubjectName(context: context) ?? '',
      classSubjectId: widget.exam.classSubjectId ?? 0,
    );
    if (kDebugMode) {
      print(
          'ExamOnlineScreen: Saved pending exam state for exam ${widget.exam.id}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityCheckTimer?.cancel();
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // User is leaving the app - mark as gone to background
      if (!isExamCompleted && !_isAutoSubmittingOnResume) {
        _hasGoneToBackground = true;
        // Update pending exam state with latest answers before going to background
        _savePendingExamState();
        if (kDebugMode) {
          print(
              'ExamOnlineScreen: App paused - marked for auto-submit on resume');
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // User returned to the app
      if (_hasGoneToBackground &&
          !isExamCompleted &&
          !_isAutoSubmittingOnResume) {
        if (kDebugMode) {
          print(
              'ExamOnlineScreen: App resumed after background - auto-submitting exam');
        }
        _hasGoneToBackground = false;
        _isAutoSubmittingOnResume = true;

        // Auto-submit the exam immediately
        _autoSubmitAndNavigateToResult();
      }
    }
  }

  /// Auto-submit the exam and navigate to result screen
  void _autoSubmitAndNavigateToResult() {
    // Cancel the timer
    timerKey.currentState?.cancelTimer();

    // Mark exam as completed to prevent back navigation issues
    setState(() {
      isExamCompleted = true;
      isExitTriggeredSubmission = true;
    });

    // Submit the exam
    submitExamAnswers();
  }

  void onBackPress() {
    // Prevent multiple dialogs from opening
    if (isExitDialogOpen) return;

    isExitDialogOpen = true;

    if (!isExamCompleted) {
      // Use WidgetsBinding to show dialog after current frame to avoid navigation conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && isExitDialogOpen) {
          _showExitConfirmationDialog();
        }
      });
    } else {
      // If exam is completed, allow back navigation
      isExitDialogOpen = false;
      Get.back();
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            Utils.getTranslatedLabel(quitExamKey),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                Utils.getTranslatedLabel(noKey),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () {
                setState(() {
                  isExitDialogOpen = false;
                });
                Navigator.of(context).pop(); // Close dialog only
              },
            ),
            TextButton(
              child: Text(
                Utils.getTranslatedLabel(yesKey),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                setState(() {
                  isExitDialogOpen = false;
                  isExamCompleted =
                      true; // Mark exam as completed to allow navigation
                  isExitTriggeredSubmission =
                      true; // Track that this was an exit-triggered submission
                });
                Navigator.of(context).pop(); // Close dialog
                submitExamAnswers(); // Submit exam - BlocListener will handle navigation
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildOnlineExamAppbar(BuildContext context) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomBackButton(onTap: onBackPress),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: Text(
                widget.exam.subject?.getSubjectName(context: context) ?? "",
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 25.0),
              child: ExamTimerContainer(
                navigateToResultScreen: finishExamOnline,
                examDurationInMinutes: widget.exam.duration ?? 0,
                key: timerKey,
              ),
            ),
          ),
          Align(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.exam.title ?? "",
                    style: TextStyle(
                      color: Utils.getColorScheme(context).surface,
                      fontSize: Utils.screenSubTitleFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Utils.getColorScheme(context).surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Flexible(
                  child: Text(
                    "${widget.exam.totalMarks} ${Utils.getTranslatedLabel(marksKey)}",
                    style: TextStyle(
                      color: Utils.getColorScheme(context).surface,
                      fontSize: Utils.screenSubTitleFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showExamQuestionStatusBottomSheet() {
    final submitOnlineExamAnswersCubit =
        context.read<SubmitOnlineExamAnswersCubit>();
    isExamQuestionStatusBottomsheetOpen = true;
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      isDismissible: !isSubmissionInProgress,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) {
        return ExamQuestionStatusBottomSheetContainer(
          submitOnlineExamAnswersCubit: submitOnlineExamAnswersCubit,
          onlineExamId: widget.exam.id ?? 0,
          submittedAnswers: _selectedAnswersWithQuestionId,
          navigateToResultScreen: finishExamOnline,
          pageController: pageController,
        );
      },
    );
    /*
    .then((value) {
      isExamQuestionStatusBottomsheetOpen = false;
    });
     */
  }

  void submitQuestionAnswer(Question question, AnswerOption answerOption) {
    List<int> submittedAnswerIds =
        _selectedAnswersWithQuestionId[question.id] ?? List<int>.from([]);

    final int answerId = answerOption.id ?? 0;
    final int totalCorrectAnswers = question.totalCorrectAnswer();

    // Check if the clicked option is already selected
    if (submittedAnswerIds.contains(answerId)) {
      // If already selected, deselect it (toggle behavior)
      submittedAnswerIds.remove(answerId);
    } else {
      // For MCQ (single answer questions)
      // Note: During exam, API doesn't send correct answer info, so totalCorrectAnswers will be 0
      // We treat questions with totalCorrectAnswers <= 1 as MCQ (single selection)
      if (totalCorrectAnswers <= 1) {
        // Clear all previous selections and select only the new option
        submittedAnswerIds.clear();
        submittedAnswerIds.add(answerId);
      } else {
        // For multiple answer questions (totalCorrectAnswers > 1)
        if (submittedAnswerIds.length >= totalCorrectAnswers) {
          // If maximum answers already selected, remove the first one
          submittedAnswerIds.removeAt(0);
        }
        // Add the new selection
        submittedAnswerIds.add(answerId);
      }
    }

    _selectedAnswersWithQuestionId[question.id ?? 0] = submittedAnswerIds;

    setState(() {});
  }

  /// Check if internet is available by attempting to lookup a reliable host
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Start periodic connectivity checks to auto-retry submission
  void _startConnectivityCheck() {
    if (_connectivityCheckTimer?.isActive ?? false) return;

    _connectivityCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final hasConnection = await _checkInternetConnectivity();
      if (hasConnection && _hasPendingSubmission) {
        timer.cancel();
        setState(() {
          _isWaitingForConnection = false;
        });
        // Auto-retry submission
        submitExamAnswers();
      }
    });
  }

  /// Stop connectivity check timer
  void _stopConnectivityCheck() {
    _connectivityCheckTimer?.cancel();
    _connectivityCheckTimer = null;
  }

  /// Handle submission failure due to network error
  void _handleNetworkSubmissionFailure(String errorMessage) {
    // Check if this is a network-related error
    final isNetworkError =
        errorMessage == ErrorMessageKeysAndCode.noInternetCode ||
            errorMessage.toLowerCase().contains('socketexception') ||
            errorMessage.toLowerCase().contains('connection') ||
            errorMessage.toLowerCase().contains('network') ||
            errorMessage.toLowerCase().contains('timeout');

    if (isNetworkError) {
      // Set pending submission flag
      _hasPendingSubmission = true;
      _isWaitingForConnection = true;

      // Pause the exam timer while waiting
      timerKey.currentState?.cancelTimer();

      // Start connectivity monitoring
      _startConnectivityCheck();

      setState(() {});
    }
  }

  void submitExamAnswers() {
    // Clear pending flag since we're attempting submission
    _hasPendingSubmission = false;
    _stopConnectivityCheck();

    context.read<SubmitOnlineExamAnswersCubit>().submitAnswers(
        examId: widget.exam.id ?? 0, answers: _selectedAnswersWithQuestionId);
  }

  void finishExamOnline() {
    Future.delayed(Duration.zero, () {
      timerKey.currentState?.cancelTimer();
    });

    if (isExamQuestionStatusBottomsheetOpen && !isSubmissionInProgress) {
      Get.back();
    }
    if (isExitDialogOpen) {
      Get.back();
    }
    if (!isExamCompleted) {
      submitExamAnswers();
    }
  }

  Widget buildBottomButton() {
    return Container(
      width: MediaQuery.of(context).size.width * (0.345),
      height: MediaQuery.of(context).size.height * (0.045),
      decoration: BoxDecoration(
        color: Utils.getColorScheme(context).primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: IconButton(
        onPressed: () {
          showExamQuestionStatusBottomSheet();
        },
        padding: EdgeInsets.zero,
        color: Utils.getColorScheme(context).surface,
        highlightColor: Colors.transparent,
        icon: const Icon(
          Icons.keyboard_arrow_up_rounded,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildQuestions() {
    return BlocBuilder<OnlineExamQuestionsCubit, OnlineExamQuestionsState>(
      builder: (context, state) {
        if (state is OnlineExamQuestionsFetchSuccess) {
          return PageView.builder(
            onPageChanged: (index) {
              currentQuestionIndex = index;
              setState(() {});
            },
            controller: pageController,
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final question = state.questions[index];
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
                  ),
                  bottom: MediaQuery.of(context).size.height * 0.06,
                ),
                child: Column(
                  children: [
                    QuestionContainer(
                      questionColor: Utils.getColorScheme(context).secondary,
                      questionNumber: index + 1,
                      question: question,
                    ),
                    (question.totalCorrectAnswer() > 1)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "${Utils.getTranslatedLabel(noteKey)} ${Utils.getTranslatedLabel(selectKey)} ${question.totalCorrectAnswer()} ${Utils.getTranslatedLabel(examMultipleAnsNoteKey)}",
                                    style: TextStyle(
                                      color: Utils.getColorScheme(context)
                                          .onSurface,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(
                      height: 25,
                    ),
                    ...(question.options ?? [])
                        .map(
                          (option) => OptionContainer(
                            question: question,
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * (0.85),
                              maxHeight: MediaQuery.of(context).size.height *
                                  Utils.questionContainerHeightPercentage,
                            ),
                            answerOption: option,
                            submittedAnswerIds:
                                _selectedAnswersWithQuestionId[question.id] ??
                                    List<int>.from([]),
                            submitAnswer: submitQuestionAnswer,
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget buildExamCompleteDialog() {
    isExamCompleted = true;
    return Container(
      alignment: Alignment.center,
      color: Utils.getColorScheme(context).secondary.withValues(alpha: 0.5),
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/payment_success.json",
              animate: true,
            ),
            Text(
              Utils.getTranslatedLabel(examCompletedKey),
              textAlign: TextAlign.center,
              style: TextStyle(color: Utils.getColorScheme(context).secondary),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          CustomRoundedButton(
            backgroundColor: Utils.getColorScheme(context).primary,
            buttonTitle: Utils.getTranslatedLabel(homeKey),
            titleColor: Theme.of(context).scaffoldBackgroundColor,
            showBorder: false,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              Get.back();
              //goto 1st tab [Home] in bottomNavigatonbar
              Get.until((route) => route.isFirst);
              HomeScreen.currentState?.changeBottomNavItem(0);
            },
          ),
          CustomRoundedButton(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            buttonTitle: Utils.getTranslatedLabel(resultKey),
            titleColor: Utils.getColorScheme(context).primary,
            showBorder: true,
            borderColor: Utils.getColorScheme(context).primary,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              context.read<ExamsOnlineCubit>().getExamsOnline(
                  classSubjectId: context
                              .read<ExamTabSelectionCubit>()
                              .state
                              .examFilterByClassSubjectId ==
                          0
                      ? 0
                      : widget.exam.classSubjectId ?? 0,
                  childId: 0,
                  useParentApi: false);

              Get.offNamed(
                Routes.resultOnline,
                arguments: {
                  "examId": widget.exam.id,
                  "examName": widget.exam.title,
                  "subjectName":
                      widget.exam.subject?.getSubjectName(context: context) ??
                          "",
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isExamCompleted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isExamCompleted) {
          onBackPress();
        }
      },
      child: Scaffold(
        floatingActionButton: buildBottomButton(),
        //bottom center button
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        body: Stack(
          children: [
            _buildQuestions(),
            buildOnlineExamAppbar(context),
            BlocConsumer<SubmitOnlineExamAnswersCubit,
                SubmitOnlineExamAnswersState>(
              listener: (context, state) {
                if (state is SubmitOnlineExamAnswersFailure) {
                  isSubmissionInProgress = false;
                  // Reset flags on failure so user can try again
                  if (isExitTriggeredSubmission) {
                    setState(() {
                      isExamCompleted = false;
                      isExitTriggeredSubmission = false;
                    });
                  }

                  // Handle network failure - start auto-retry mechanism
                  _handleNetworkSubmissionFailure(state.errorMessage);

                  // Only show snackbar if not waiting for connection
                  // (to avoid repeated error messages during auto-retry)
                  if (!_isWaitingForConnection) {
                    Utils.showCustomSnackBar(
                      context: context,
                      errorMessage: Utils.getErrorMessageFromErrorCode(
                        context,
                        state.errorMessage,
                      ),
                      backgroundColor: Utils.getColorScheme(context).error,
                    );
                  }
                }
                if (state is SubmitOnlineExamAnswersSuccess) {
                  isExamQuestionStatusBottomsheetOpen = true;
                  isSubmissionInProgress = false;
                  _isWaitingForConnection = false;
                  _hasPendingSubmission = false;
                  _stopConnectivityCheck();

                  // Clear pending exam from Hive after successful submission
                  PendingExamSubmissionRepository.clearPendingExam();

                  // The buildExamCompleteDialog will be shown by BlocBuilder
                  // User can then choose to go to Home or Result screen
                }
                if (state is SubmitOnlineExamAnswersInProgress) {
                  isSubmissionInProgress = true;
                }
              },
              builder: (context, state) {
                if (state is SubmitOnlineExamAnswersSuccess) {
                  return buildExamCompleteDialog();
                }
                if (isSubmissionInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show waiting for connection overlay
                if (_isWaitingForConnection) {
                  return Container(
                    alignment: Alignment.center,
                    color: Utils.getColorScheme(context)
                        .secondary
                        .withValues(alpha: 0.7),
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            Utils.getTranslatedLabel(noInternetKey),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Utils.getColorScheme(context).secondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            Utils.getTranslatedLabel(waitingForConnectionKey),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Utils.getColorScheme(context)
                                  .secondary
                                  .withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Allow manual retry
                            submitExamAnswers();
                          },
                          child: Text(
                            Utils.getTranslatedLabel(retryKey),
                            style: TextStyle(
                              color: Utils.getColorScheme(context).primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
