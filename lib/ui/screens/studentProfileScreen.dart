import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/downloadStudentIdCardCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/studentAllProfileDetailsCubit.dart';
import 'package:eschool/cubits/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/appIcon.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';

class StudentProfileScreen extends StatefulWidget {
  final int? childId;
  final int? userId;

  const StudentProfileScreen({Key? key, this.childId, this.userId})
      : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return BlocProvider(
      create: (context) => StudentAllProfileDetailsCubit(StudentRepository()),
      child: StudentProfileScreen(
        childId: arguments?['childId'] as int?,
        userId: arguments?['userId'] as int?,
      ),
    );
  }
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchStudentAllProfileDetails();
    });
  }

  void fetchStudentAllProfileDetails() {
    context.read<StudentAllProfileDetailsCubit>().getStudentAllProfileDetails(
        useParentApi: widget.childId != null, childId: widget.childId);
  }

  /// Opens a file in the file viewer screen
  void _openFile(String fileUrl, String fileName) {
    if (fileUrl.isEmpty) return;

    Get.toNamed(
      Routes.fileViewer,
      arguments: {
        'fileUrl': fileUrl,
        'fileName': fileName,
      },
    );
  }

  /// Formats the display value for different field types
  String _formatFieldValue(String? data, String? fieldType) {
    if (data == null || data.isEmpty) {
      return Utils.formatEmptyValue('');
    }

    // For checkbox fields, parse JSON array and display as comma-separated values
    if (fieldType?.toLowerCase() == 'checkbox') {
      try {
        final List<dynamic> values = jsonDecode(data);
        return values.join(', ');
      } catch (e) {
        return data;
      }
    }

    return Utils.formatEmptyValue(data);
  }

  /// Returns the student's phone number with the country code prefixed
  /// The student profile api returns the number at the root level where as
  /// the child profile api returns it inside the user object
  String _getStudentPhoneNumber(Student studentDetails) {
    final String mobile = (studentDetails.mobile ?? "").trim().isNotEmpty
        ? studentDetails.mobile!
        : (studentDetails.childUserDetails?.mobile ?? "");

    final String countryCode =
        (studentDetails.countryCode ?? "").trim().isNotEmpty
            ? studentDetails.countryCode!
            : (studentDetails.childUserDetails?.countryCode ?? "");

    return Utils.formatMobileNumber(countryCode: countryCode, mobile: mobile);
  }

  Widget _buildProfileDetailsTile({
    required String label,
    required String value,
    required String iconUrl,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12.5),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Color(0x1a212121),
                offset: Offset(0, 10),
                blurRadius: 16,
              )
            ],
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: AppIcon(
            iconUrl,
            color: iconColor ?? Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * (0.05),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15.0),
              child: content,
            )
          : content,
    );
  }

  void _showIdCardDownloadDialog({int? userId}) {
    Get.dialog(
      BlocProvider(
        create: (context) => DownloadStudentIdCardCubit(StudentRepository()),
        child: DownloadStudentIdCardDialog(userId: userId),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildIdCardButton({int? userId}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showIdCardDownloadDialog(userId: userId),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: SvgPicture.asset(
                  Utils.getImagePath("school_idcard.svg"),
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                Utils.getTranslatedLabel(idCardKey),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        content: Text(Utils.getTranslatedLabel(sureToLogoutKey)),
        actions: [
          CupertinoButton(
            child: Text(Utils.getTranslatedLabel(yesKey)),
            onPressed: () {
              context.read<StudentSubjectsAndSlidersCubit>().clearSubjects();
              context.read<AuthCubit>().signOut();
              Get.back();
              Get.offNamed(Routes.auth);
            },
          ),
          CupertinoButton(
            child: Text(Utils.getTranslatedLabel(noKey)),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: CustomAppBar(
        title: Utils.getTranslatedLabel(profileKey),
        // Only show logout button when viewing own profile (not parent viewing child)
        trailingWidget: widget.childId == null
            ? GestureDetector(
                onTap: _showLogoutDialog,
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: AppIcon(
                    Utils.getImagePath("logout_icon.svg"),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildProfileDetailsContainer({required Student studentDetails}) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                final imageUrl = studentDetails.image ?? '';
                if (imageUrl.isNotEmpty) {
                  Utils.showImagePreview(
                    context: context,
                    imageUrl: imageUrl,
                    heroTag: 'student_profile_image',
                  );
                }
              },
              child: Hero(
                tag: 'student_profile_image',
                child: Container(
                  width: MediaQuery.of(context).size.width * (0.25),
                  height: MediaQuery.of(context).size.width * (0.25),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: CustomUserProfileImageWidget(
                    profileUrl: studentDetails.image ?? "",
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              studentDetails.getFullName(),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Text(
              "${Utils.getTranslatedLabel(grNumberKey)} - ${studentDetails.admissionNo}",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(
              height: 12.0,
            ),
            if (Utils.isModuleEnabled(
              context: context,
              moduleId: certificateManagementModuleId.toString(),
            ))
              _buildIdCardButton(
                  userId: widget.userId ??
                      studentDetails.userId ??
                      studentDetails.childUserDetails?.id),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * (0.075),
              ),
              child: Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * (0.075),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      Utils.getTranslatedLabel(personalDetailsKey),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(schoolKey),
                    value: Utils.formatEmptyValue(
                        ("${studentDetails.school?.name} (${studentDetails.school?.code})")),
                    iconUrl: Utils.getImagePath("school.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(classKey),
                    value: Utils.formatEmptyValue(
                      studentDetails.classSection?.fullName ?? "",
                    ),
                    iconUrl: Utils.getImagePath("user_pro_class_icon.svg"),
                  ),
                  (studentDetails.classSection?.classDetails
                                  ?.includeSemesters ??
                              0) ==
                          1
                      ? _buildProfileDetailsTile(
                          label: Utils.getTranslatedLabel(semesterKey),
                          value: Utils.formatEmptyValue(
                            context
                                    .read<SchoolConfigurationCubit>()
                                    .getSchoolConfiguration()
                                    .semesterDetails
                                    .name ??
                                "",
                          ),
                          iconColor: Theme.of(context).scaffoldBackgroundColor,
                          iconUrl: Utils.getImagePath("sem_pro_icon.svg"),
                        )
                      : const SizedBox(),
                  (studentDetails.classSection?.classDetails?.streamDetails
                                  ?.name ??
                              "")
                          .isNotEmpty
                      ? _buildProfileDetailsTile(
                          label: Utils.getTranslatedLabel(streamKey),
                          value: Utils.formatEmptyValue(
                            studentDetails.classSection?.classDetails
                                    ?.streamDetails?.name ??
                                "",
                          ),
                          iconColor: Theme.of(context).scaffoldBackgroundColor,
                          iconUrl: Utils.getImagePath("stream_pro_icon.svg"),
                        )
                      : const SizedBox(),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(mediumKey),
                    value: Utils.formatEmptyValue(
                      studentDetails.classSection?.medium?.name ?? "",
                    ),
                    iconUrl: Utils.getImagePath("medium_icon.svg"),
                  ),
                  if (studentDetails.classSection?.classDetails?.shift?.name !=
                          null &&
                      (studentDetails.classSection?.classDetails?.shift?.name ??
                              "")
                          .trim()
                          .isNotEmpty)
                    _buildProfileDetailsTile(
                      label: Utils.getTranslatedLabel(shiftKey),
                      value: Utils.formatEmptyValue(
                        "${studentDetails.classSection!.classDetails!.shift!.name} (${studentDetails.classSection!.classDetails!.shift!.startToEndTime ?? ''})",
                      ),
                      iconUrl: Utils.getImagePath("user_pro_shift_icon.svg"),
                    ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(rollNumberKey),
                    value: studentDetails.rollNumber.toString(),
                    iconUrl: Utils.getImagePath("user_pro_roll_no_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(dateOfBirthKey),
                    value: Utils.formatEmptyValue(studentDetails.dob ?? ""),
                    iconUrl: Utils.getImagePath("user_pro_dob_icon.svg"),
                  ),
                  if (_getStudentPhoneNumber(studentDetails).isNotEmpty)
                    _buildProfileDetailsTile(
                      label: Utils.getTranslatedLabel(phoneNumberKey),
                      value: _getStudentPhoneNumber(studentDetails),
                      iconUrl: Utils.getImagePath("user_pro_phone_icon.svg"),
                    ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(
                      currentAddressKey,
                    ),
                    value: Utils.formatEmptyValue(
                      studentDetails.currentAddress ?? "",
                    ),
                    iconUrl: Utils.getImagePath("user_pro_address_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(
                      permanentAddressKey,
                    ),
                    value: Utils.formatEmptyValue(
                      studentDetails.permanentAddress ?? "",
                    ),
                    iconUrl: Utils.getImagePath("user_pro_address_icon.svg"),
                  ),
                  ...(studentDetails.studentProfileExtraDetails ?? []).map(
                    (details) {
                      final fieldType = details.formField?.type;
                      final isFileType = fieldType?.toLowerCase() == 'file';
                      final fileUrl = details.fileUrl ?? '';

                      return _buildProfileDetailsTile(
                        label: details.formField?.name ?? "",
                        value: isFileType && fileUrl.isNotEmpty
                            ? Utils.getTranslatedLabel(tapToViewFileKey)
                            : _formatFieldValue(
                                details.data,
                                fieldType,
                              ),
                        iconColor: Theme.of(context).scaffoldBackgroundColor,
                        iconUrl: Utils.getIconForFieldType(fieldType),
                        onTap: isFileType && fileUrl.isNotEmpty
                            ? () => _openFile(
                                  fileUrl,
                                  details.formField?.name ?? 'File',
                                )
                            : null,
                      );
                    },
                  ).toList(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDetailsValueShimmerLoading(
      BoxConstraints boxConstraints) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        ShimmerLoadingContainer(
          child: CustomShimmerContainer(
            margin: EdgeInsetsDirectional.only(
              end: boxConstraints.maxWidth * (0.7),
            ),
            height: 8,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ShimmerLoadingContainer(
          child: CustomShimmerContainer(
            margin: EdgeInsetsDirectional.only(
              end: boxConstraints.maxWidth * (0.5),
            ),
            height: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDetailsShimmerLoading() {
    return Padding(
      padding: EdgeInsets.only(
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Column(
              children: [
                ShimmerLoadingContainer(
                  child: Container(
                    width: MediaQuery.of(context).size.width * (0.25),
                    height: MediaQuery.of(context).size.width * (0.25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerLoadingContainer(
                        child: Divider(
                          color: shimmerContentColor,
                          height: 2,
                        ),
                      ),
                      _buildStudentDetailsValueShimmerLoading(boxConstraints),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildStudentDetailsValueShimmerLoading(boxConstraints),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildStudentDetailsValueShimmerLoading(boxConstraints),
                      const SizedBox(
                        height: 20,
                      ),
                      _buildStudentDetailsValueShimmerLoading(boxConstraints),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<StudentAllProfileDetailsCubit,
              StudentAllProfileDetailsState>(builder: (context, state) {
            if (state is StudentAllProfileDetailsFetchSuccess) {
              return _buildProfileDetailsContainer(
                  studentDetails: state.student);
            }
            if (state is StudentAllProfileDetailsFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  onTapRetry: () {
                    fetchStudentAllProfileDetails();
                  },
                ),
              );
            }

            return _buildStudentDetailsShimmerLoading();
          }),
          _buildAppBar(),
        ],
      ),
    );
  }
}

class DownloadStudentIdCardDialog extends StatefulWidget {
  final int? userId;

  const DownloadStudentIdCardDialog({super.key, this.userId});

  @override
  State<DownloadStudentIdCardDialog> createState() =>
      _DownloadStudentIdCardDialogState();
}

class _DownloadStudentIdCardDialogState
    extends State<DownloadStudentIdCardDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context
          .read<DownloadStudentIdCardCubit>()
          .downloadStudentIdCard(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadStudentIdCardCubit, DownloadStudentIdCardState>(
      listener: (context, state) {
        if (state is DownloadStudentIdCardSuccess) {
          Get.back();
          OpenFile.open(state.downloadedFilePath);
        } else if (state is DownloadStudentIdCardFailure) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: Utils.getTranslatedLabel(state.errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
          Get.back();
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            CustomCircularProgressIndicator(
              widthAndHeight: 15.0,
              strokeWidth: 2.0,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10.0),
            Flexible(
              child: Text(
                Utils.getTranslatedLabel(downloadingIdCardKey),
                style: const TextStyle(fontSize: 15.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
