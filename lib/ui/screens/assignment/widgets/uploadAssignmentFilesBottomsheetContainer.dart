import 'package:dotted_border/dotted_border.dart';
import 'package:eschool/cubits/uploadAssignmentCubit.dart';
import 'package:eschool/data/models/assignment.dart';
import 'package:eschool/ui/widgets/bottomsheetTopTitleAndCloseButton.dart';

import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

enum SubmissionType { file, link }

class UploadAssignmentFilesBottomsheetContainer extends StatefulWidget {
  final Assignment assignment;
  final bool isResubmission;

  const UploadAssignmentFilesBottomsheetContainer({
    Key? key,
    required this.assignment,
    this.isResubmission = false,
  }) : super(key: key);

  @override
  State<UploadAssignmentFilesBottomsheetContainer> createState() =>
      _UploadAssignmentFilesBottomsheetContainerState();
}

class _UploadAssignmentFilesBottomsheetContainerState
    extends State<UploadAssignmentFilesBottomsheetContainer> {
  SubmissionType? selectedSubmissionType;
  List<PlatformFile> uploadedFiles = [];
  final TextEditingController linkUrlController = TextEditingController();

  @override
  void dispose() {
    linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      uploadedFiles.addAll(result.files);
      setState(() {});
    }
  }

  Future<void> _addFiles() async {
    try {
      await _pickFiles();
    } catch (e) {
      debugPrint("this is the $e");
    }
  }

  Widget _buildUploadedFileContainer(int fileIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10.0),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Row(
            children: [
              SizedBox(
                width: boxConstraints.maxWidth * (0.75),
                child: Text(
                  uploadedFiles[fileIndex].name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (context.read<UploadAssignmentCubit>().state
                      is UploadAssignmentInProgress) {
                    return;
                  }
                  uploadedFiles.removeAt(fileIndex);
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubmissionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSubmissionTypeOption(
                type: SubmissionType.file,
                icon: Icons.upload_file,
                label: uploadFileKey,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * (0.04)),
            Expanded(
              child: _buildSubmissionTypeOption(
                type: SubmissionType.link,
                icon: Icons.link,
                label: addLinkKey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmissionTypeOption({
    required SubmissionType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedSubmissionType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        if (context.read<UploadAssignmentCubit>().state
            is UploadAssignmentInProgress) {
          return;
        }
        setState(() {
          selectedSubmissionType = type;
          // Clear the other type's data when switching
          if (type == SubmissionType.file) {
            linkUrlController.clear();
          } else {
            uploadedFiles.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              Utils.getTranslatedLabel(label),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    if (selectedSubmissionType != SubmissionType.file) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * (0.025)),
        uploadedFiles.isNotEmpty
            ? Text(
                Utils.getTranslatedLabel(
                  assignmentSubmissionDisclaimerKey,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const SizedBox(),
        SizedBox(
          height: uploadedFiles.isNotEmpty
              ? MediaQuery.of(context).size.height * (0.025)
              : 0,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            _addFiles();
          },
          child: DottedBorder(
            borderType: BorderType.RRect,
            dashPattern: const [10, 10],
            radius: const Radius.circular(15.0),
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            child: Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width * (0.8),
              height: MediaQuery.of(context).size.height * (0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 15,
                          offset: const Offset(0, 1.5),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        )
                      ],
                    ),
                    width: 25,
                    height: 25,
                    child: Icon(
                      Icons.add,
                      size: 15,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * (0.05),
                  ),
                  Text(
                    Utils.getTranslatedLabel(addFilesKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * (0.025),
        ),
        ...List.generate(uploadedFiles.length, (index) => index)
            .map((fileIndex) => _buildUploadedFileContainer(fileIndex))
            .toList(),
      ],
    );
  }

  Widget _buildLinkInputSection() {
    if (selectedSubmissionType != SubmissionType.link) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * (0.025)),
        Text(
          Utils.getTranslatedLabel(enterLinkKey),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * (0.015)),
        TextField(
          controller: linkUrlController,
          enabled: context.read<UploadAssignmentCubit>().state
              is! UploadAssignmentInProgress,
          decoration: InputDecoration(
            hintText: Utils.getTranslatedLabel(linkUrlKey),
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.link,
              color: Theme.of(context).colorScheme.primary,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  bool _canSubmit() {
    if (selectedSubmissionType == SubmissionType.file) {
      return uploadedFiles.isNotEmpty;
    } else if (selectedSubmissionType == SubmissionType.link) {
      return linkUrlController.text.trim().isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (context.read<UploadAssignmentCubit>().state
            is UploadAssignmentInProgress) {
          context.read<UploadAssignmentCubit>().cancelUploadAssignmentProcess();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * (0.075),
            vertical: MediaQuery.of(context).size.height * (0.04),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomsheetTopTitleAndCloseButton(
                onTapCloseButton: () {
                  if (context.read<UploadAssignmentCubit>().state
                      is UploadAssignmentInProgress) {
                    context
                        .read<UploadAssignmentCubit>()
                        .cancelUploadAssignmentProcess();
                  }
                  Get.back();
                },
                titleKey: widget.isResubmission
                    ? resubmitAssignmentKey
                    : uploadAssignmentKey,
              ),
              widget.isResubmission
                  ? Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.015,
                        bottom: MediaQuery.of(context).size.height * 0.02,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              Utils.getTranslatedLabel(resubmissionInfoKey),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              _buildSubmissionTypeSelector(),
              _buildFileUploadSection(),
              _buildLinkInputSection(),
              _canSubmit()
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * (0.025),
                    )
                  : const SizedBox(),
              _canSubmit()
                  ? Center(
                      child: BlocConsumer<UploadAssignmentCubit,
                          UploadAssignmentState>(
                        listener: (context, state) {
                          if (state is UploadAssignmentFetchSuccess) {
                            Get.back(result: {
                              "error": false,
                              "assignmentSubmission":
                                  state.assignmentSubmission,
                              "message": state.successMessage,
                            });
                          } else if (state is UploadAssignmentFailure) {
                            Get.back(result: {
                              "error": true,
                              "message": state.errorMessage
                            });
                          }
                        },
                        builder: (context, state) {
                          return CustomRoundedButton(
                            onTap: () {
                              if (state is UploadAssignmentInProgress) {
                                return;
                              }

                              if (selectedSubmissionType ==
                                  SubmissionType.file) {
                                final filePaths = uploadedFiles
                                    .map((file) => file.path)
                                    .whereType<String>()
                                    .toList();
                                if (filePaths.isNotEmpty) {
                                  context
                                      .read<UploadAssignmentCubit>()
                                      .uploadAssignment(
                                        assignmentId: widget.assignment.id,
                                        filePaths: filePaths,
                                      );
                                }
                              } else if (selectedSubmissionType ==
                                  SubmissionType.link) {
                                final linkUrl = linkUrlController.text.trim();
                                if (linkUrl.isNotEmpty) {
                                  context
                                      .read<UploadAssignmentCubit>()
                                      .uploadAssignment(
                                        assignmentId: widget.assignment.id,
                                        linkUrl: linkUrl,
                                      );
                                }
                              }
                            },
                            height: 40,
                            widthPercentage: state is UploadAssignmentInProgress
                                ? 0.65
                                : 0.35,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            buttonTitle: state is UploadAssignmentInProgress
                                ? "${Utils.getTranslatedLabel(submittingKey)} (${state.uploadedProgress.toStringAsFixed(2)})%"
                                : Utils.getTranslatedLabel(submitKey),
                            showBorder: false,
                          );
                        },
                      ),
                    )
                  : const SizedBox()
            ],
          ),
        ),
      ),
    );
  }
}
