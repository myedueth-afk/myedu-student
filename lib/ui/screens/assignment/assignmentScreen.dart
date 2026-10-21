import 'package:eschool/cubits/assignmentsCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/undoAssignmentSubmissionCubit.dart';
import 'package:eschool/cubits/uploadAssignmentCubit.dart';
import 'package:eschool/data/models/assignment.dart';
import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/data/repositories/assignmentRepository.dart';
import 'package:eschool/ui/screens/assignment/widgets/undoAssignmentBottomsheetContainer.dart';
import 'package:eschool/ui/screens/assignment/widgets/uploadAssignmentFilesBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/studyMaterialWithDownloadButtonContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/route_manager.dart';

class AssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentScreen({Key? key, required this.assignment})
      : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();

  static Widget routeInstance() {
    return AssignmentScreen(
      assignment: Get.arguments as Assignment,
    );
  }
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  //if this is true, we can show the undo assignment submission button
  bool isUndoAssignmentSubmissionButtonToBeShown = false;

  late bool assignmentSubmitted =
      submittedAssignment.assignmentSubmission.id != 0;
  late Assignment submittedAssignment = widget.assignment;

  void uploadAssignment() {
    // Check if this is a resubmission scenario
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );
    bool isResubmission = assignmentStatusKey == resubmittedKey;

    Utils.showBottomSheet(
      child: BlocProvider<UploadAssignmentCubit>(
        create: (_) => UploadAssignmentCubit(AssignmentRepository()),
        child: UploadAssignmentFilesBottomsheetContainer(
          assignment: submittedAssignment,
          isResubmission: isResubmission,
        ),
      ),
      context: context,
      enableDrag: false,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: value['message'],
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(value['assignmentSubmission']);
          assignmentSubmitted = true;
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);

          // Show success message from API
          Utils.showCustomSnackBar(
            context: context,
            errorMessage:
                value['message'] ?? 'Assignment submitted successfully',
            backgroundColor: Theme.of(context).colorScheme.primary,
          );

          setState(() {});
        }
      }
    });
  }

  void undoAssignment() {
    // Get current assignment status
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    // For resubmitted assignments (after rejection), directly open upload bottomsheet
    // without calling delete API - backend will update the existing submission
    if (assignmentStatusKey == resubmittedKey) {
      uploadAssignment();
      return;
    }

    // For regular "in review" assignments, use the existing flow with delete API
    Utils.showBottomSheet(
      child: BlocProvider<UndoAssignmentSubmissionCubit>(
        create: (_) => UndoAssignmentSubmissionCubit(AssignmentRepository()),
        child: UndoAssignmentBottomsheetContainer(
          assignmentSubmissionId: submittedAssignment.assignmentSubmission.id,
        ),
      ),
      context: context,
      enableDrag: false,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: Utils.getErrorMessageFromErrorCode(
              context,
              value['message'].toString(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(AssignmentSubmission.fromJson({}));
          assignmentSubmitted = false;
          isUndoAssignmentSubmissionButtonToBeShown = false;
          setState(() {});
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);
          uploadAssignment();
        }
      }
    });
  }

  TextStyle _getAssignmentDetailsLabelValueTextStyle() {
    return TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
  }

  TextStyle _getAssignmentDetailsLabelTextStyle() {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
  }

  bool _showUploadAssignmentButton() {
    if (context.read<AuthCubit>().isParent()) {
      return false;
    }

    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    DateTime now = DateTime.now();

    // Parse the base due date from due_date_original (stable format)
    DateTime? baseDueDate = submittedAssignment.getParsedDueDate();
    if (baseDueDate == null) {
      // If parsing fails, hide the button to be safe
      return false;
    }

    // Calculate the extended deadline (includes extra resubmission days
    // with end-of-day precision when resubmission is allowed)
    DateTime? extendedDeadline = submittedAssignment.getEffectiveDeadline(
      includeResubmissionDays: true,
    );

    // In-review: allow undo if still within the effective deadline.
    // When resubmission is enabled, use the extended deadline (base due date
    // + extra resubmission days) so the student can undo and resubmit within
    // the full allowed window. Otherwise, fall back to base due date.
    if (assignmentStatusKey == inReviewKey) {
      DateTime effectiveDeadline = extendedDeadline ?? baseDueDate;
      if (!now.isAfter(effectiveDeadline)) {
        isUndoAssignmentSubmissionButtonToBeShown = true;
        return true;
      }
      return false;
    }

    // Resubmitted: allow undo if within extended deadline
    if (assignmentStatusKey == resubmittedKey) {
      if (extendedDeadline != null && !now.isAfter(extendedDeadline)) {
        isUndoAssignmentSubmissionButtonToBeShown = true;
        return true;
      }
      return false;
    }

    // Accepted: no further action allowed
    if (assignmentStatusKey == acceptedKey) {
      return false;
    }

    // Rejected: allow resubmission within extended deadline
    if (assignmentStatusKey == rejectedKey) {
      if (extendedDeadline != null && !now.isAfter(extendedDeadline)) {
        return true;
      }
      return false;
    }

    // Unsubmitted: use extended deadline if resubmission is allowed,
    // otherwise use base due date
    if (assignmentStatusKey.isEmpty ||
        submittedAssignment.assignmentSubmission.id == 0) {
      // Use the extended deadline (which accounts for extra resubmission
      // days with end-of-day precision) when resubmission is enabled.
      // Falls back to baseDueDate when resubmission is not enabled.
      DateTime effectiveDeadline = extendedDeadline ?? baseDueDate;
      if (!now.isAfter(effectiveDeadline)) {
        return true;
      }
      return false;
    }

    // Fallback: hide the button
    return false;
  }

  Widget _uploadOrUndoAssignmentButton() {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 25.0, bottom: 25.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (isUndoAssignmentSubmissionButtonToBeShown) {
              undoAssignment();
            } else {
              uploadAssignment();
            }
          },
          child: Container(
            width: 60,
            height: 60,
            padding: EdgeInsets.all(
                isUndoAssignmentSubmissionButtonToBeShown ? 18 : 15),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.275),
                )
              ],
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              Utils.getImagePath(isUndoAssignmentSubmissionButtonToBeShown
                  ? "undo_assignment_submission.svg"
                  : "file_upload_icon.svg"),
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentDetailBackgroundContainer(Widget child) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        width: MediaQuery.of(context).size.width * (0.85),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: child,
      ),
    );
  }

  Widget _buildAssignmentNameContainer() {
    return _buildAssignmentDetailBackgroundContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Utils.getTranslatedLabel(assignmentNameKey),
            style: _getAssignmentDetailsLabelTextStyle(),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Text(
            submittedAssignment.name,
            style: _getAssignmentDetailsLabelValueTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentSubjectNameContainer() {
    return _buildAssignmentDetailBackgroundContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Utils.getTranslatedLabel(subjectNameKey),
            style: _getAssignmentDetailsLabelTextStyle(),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Text(
            submittedAssignment.subject.getSubjectName(context: context),
            style: _getAssignmentDetailsLabelValueTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentPointsContainer() {
    if (submittedAssignment.points == 0) {
      return const SizedBox();
    }

    return _buildAssignmentDetailBackgroundContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Utils.getTranslatedLabel(
              assignmentSubmitted ? pointsKey : possiblePointsKey,
            ),
            style: _getAssignmentDetailsLabelTextStyle(),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Text(
            assignmentSubmitted
                ? "${submittedAssignment.assignmentSubmission.points}/${submittedAssignment.points}"
                : submittedAssignment.points.toString(),
            style: _getAssignmentDetailsLabelValueTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDueDateContainer() {
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    String dueDateToDisplay;

    //Since dueDate is now a string from API, we'll always use the raw date string
    //For resubmission cases, we'll show the original due date with a note about extra days
    if ((assignmentStatusKey == rejectedKey &&
            submittedAssignment.resubmission == 1) ||
        assignmentStatusKey == resubmittedKey) {
      dueDateToDisplay =
          "${submittedAssignment.dueDateOriginal} (+${submittedAssignment.extraDaysForResubmission} days for resubmission)";
    } else {
      // Use the due_date_original from API (stable format)
      dueDateToDisplay = submittedAssignment.dueDateOriginal;
    }

    return _buildAssignmentDetailBackgroundContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Utils.getTranslatedLabel(dueDateKey),
            style: _getAssignmentDetailsLabelTextStyle(),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Text(
            dueDateToDisplay,
            style: _getAssignmentDetailsLabelValueTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentInstructionsContainer() {
    return submittedAssignment.instructions.isEmpty
        ? const SizedBox()
        : _buildAssignmentDetailBackgroundContainer(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Utils.getTranslatedLabel(instructionsKey),
                  style: _getAssignmentDetailsLabelTextStyle(),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                Text(
                  submittedAssignment.instructions,
                  style: _getAssignmentDetailsLabelValueTextStyle(),
                ),
              ],
            ),
          );
  }

  Widget _buildAssignmentRemarksContainer() {
    if (!assignmentSubmitted) {
      return const SizedBox();
    }
    if (submittedAssignment.assignmentSubmission.feedback.isEmpty) {
      return const SizedBox();
    }
    return _buildAssignmentDetailBackgroundContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Utils.getTranslatedLabel(remarksKey),
            style: _getAssignmentDetailsLabelTextStyle(),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Text(
            submittedAssignment.assignmentSubmission.feedback,
            style: _getAssignmentDetailsLabelValueTextStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentReferenceMaterialContainer({
    required BoxConstraints boxConstraints,
    required StudyMaterial studyMaterial,
  }) {
    return StudyMaterialWithDownloadButtonContainer(
      boxConstraints: boxConstraints,
      studyMaterial: studyMaterial,
    );
  }

  Widget _buildUploadedAssignmentsContainer() {
    if (!assignmentSubmitted) {
      return const SizedBox();
    }

    return _buildAssignmentDetailBackgroundContainer(
      LayoutBuilder(
        builder: (context, boxConstraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Utils.getTranslatedLabel(myWorkKey),
                style: _getAssignmentDetailsLabelTextStyle(),
              ),
              const SizedBox(
                height: 5.0,
              ),
              ...submittedAssignment.assignmentSubmission.submittedFiles
                  .map(
                    (studyMaterial) =>
                        _buildAssignmentReferenceMaterialContainer(
                      boxConstraints: boxConstraints,
                      studyMaterial: studyMaterial,
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentReferenceMaterialsContainer() {
    if (submittedAssignment.referenceMaterials.isEmpty) {
      return const SizedBox();
    }

    return _buildAssignmentDetailBackgroundContainer(
      LayoutBuilder(
        builder: (context, boxConstraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Utils.getTranslatedLabel(referenceMaterialsKey),
                style: _getAssignmentDetailsLabelTextStyle(),
              ),
              const SizedBox(
                height: 5.0,
              ),
              ...submittedAssignment.referenceMaterials
                  .map(
                    (studyMaterial) =>
                        _buildAssignmentReferenceMaterialContainer(
                      boxConstraints: boxConstraints,
                      studyMaterial: studyMaterial,
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentDetailsContainer() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: Utils.getScrollViewBottomPadding(context),
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAssignmentNameContainer(),
          _buildAssignmentSubjectNameContainer(),
          _buildAssignmentDueDateContainer(),
          _buildAssignmentInstructionsContainer(),
          _buildAssignmentReferenceMaterialsContainer(),
          _buildUploadedAssignmentsContainer(),
          _buildAssignmentPointsContainer(),
          _buildAssignmentRemarksContainer(),
        ],
      ),
    );
  }

  String getAssignmentSubmissionStatus() {
    if (Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    ).isNotEmpty) {
      return Utils.getTranslatedLabel(
        Utils.getAssignmentSubmissionStatusKey(
          submittedAssignment.assignmentSubmission.status,
        ),
      );
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    bool shouldShowButton = _showUploadAssignmentButton();

    return Scaffold(
      body: Stack(
        children: [
          _buildAssignmentDetailsContainer(),
          CustomAppBar(
            subTitle:
                assignmentSubmitted ? getAssignmentSubmissionStatus() : null,
            title: Utils.getTranslatedLabel(assignmentKey),
            onPressBackButton: () {
              Get.back(result: submittedAssignment);
            },
          ),
          shouldShowButton ? _uploadOrUndoAssignmentButton() : const SizedBox(),
        ],
      ),
    );
  }
}
