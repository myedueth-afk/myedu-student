import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/applyStudentLeaveCubit.dart';
import 'package:eschool/cubits/leaveSettingsCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/addFilesContainer.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/attachmentPicker.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ApplyStudentLeaveScreen extends StatefulWidget {
  final int childId;

  const ApplyStudentLeaveScreen({Key? key, required this.childId})
      : super(key: key);

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ApplyStudentLeaveCubit>(
          create: (_) => ApplyStudentLeaveCubit(StudentLeaveRepository()),
        ),
        BlocProvider<LeaveSettingsCubit>(
          create: (_) => LeaveSettingsCubit(StudentLeaveRepository())
            ..fetchLeaveSettings(),
        ),
      ],
      child: ApplyStudentLeaveScreen(childId: Get.arguments as int),
    );
  }

  @override
  State<ApplyStudentLeaveScreen> createState() =>
      _ApplyStudentLeaveScreenState();
}

class _ApplyStudentLeaveScreenState extends State<ApplyStudentLeaveScreen> {
  final TextEditingController _reasonTextEditingController =
      TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  final List<PlatformFile> _selectedFiles = [];

  static const TextStyle _labelTextStyle = TextStyle(
    color: captionColor,
    fontSize: 12.0,
    height: 16 / 12,
    letterSpacing: 0.4,
  );

  @override
  void dispose() {
    _reasonTextEditingController.dispose();
    super.dispose();
  }

  void _showMessage(String labelKey) {
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel(labelKey),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  /// Parents may only apply from today onwards, and never past the end of the
  /// running session year.
  DateTime get _firstSelectableDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// End of the running session year. Null when the backend did not send a
  /// usable end date, which the caller reports rather than silently guessing a
  /// range — the same guard the staff apply-leave screen applies.
  DateTime? get _sessionYearEndDate {
    final endDate = context
        .read<SchoolConfigurationCubit>()
        .getSchoolConfiguration()
        .sessionYear
        .endDate;

    return (endDate == null || endDate.isEmpty)
        ? null
        : Utils.parseApiDate(endDate);
  }

  /// Weekly offs and public holidays are days the school is already closed, so
  /// no leave is needed for them.
  bool _isHoliday(DateTime date) {
    final leaveSettingsCubit = context.read<LeaveSettingsCubit>();
    final normalisedDate = DateTime(date.year, date.month, date.day);

    return leaveSettingsCubit.getHolidayWeekDays().contains(date.weekday) ||
        leaveSettingsCubit.getPublicHolidayDates().containsKey(normalisedDate);
  }

  /// Days in the selected range the school is actually open for.
  List<DateTime> get _workingDays {
    if (_fromDate == null || _toDate == null) {
      return [];
    }

    final totalDays = _toDate!.difference(_fromDate!).inDays;

    return List.generate(
            totalDays + 1, (i) => _fromDate!.add(Duration(days: i)))
        .where((date) => !_isHoliday(date))
        .toList();
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final sessionYearEndDate = _sessionYearEndDate;

    if (sessionYearEndDate == null) {
      _showMessage(invalidSessionYearEndDateKey);
      return;
    }

    //nothing can be applied for once the session year is over
    if (sessionYearEndDate.isBefore(_firstSelectableDate)) {
      _showMessage(sessionYearEndedKey);
      return;
    }

    final initialDate = isFromDate
        ? (_fromDate ?? _firstSelectableDate)
        : (_toDate ?? _fromDate ?? _firstSelectableDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      //the end date can never start before the chosen start date
      firstDate: isFromDate
          ? _firstSelectableDate
          : (_fromDate ?? _firstSelectableDate),
      lastDate: sessionYearEndDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  onPrimary: Theme.of(context).scaffoldBackgroundColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (isFromDate) {
        _fromDate = pickedDate;
        //keep the range valid when the new start date overtakes the end date
        if (_toDate != null && _toDate!.isBefore(pickedDate)) {
          _toDate = pickedDate;
        }
      } else {
        _toDate = pickedDate;
      }
    });
  }

  Future<void> _pickFiles() async {
    try {
      //the same two pickers iOS keeps apart as on the manual payment screen
      final files = await AttachmentPicker.pick(
        context: context,
        allowedExtensions: studentLeaveAllowedFileExtensions,
        allowMultiple: true,
      );

      if (files.isNotEmpty) {
        setState(() => _selectedFiles.addAll(files));
      }
    } catch (e) {
      if (!mounted) return;
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getErrorMessageFromErrorCode(context, e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Returns the label key of the first failed rule, or null when the form is
  /// ready to submit.
  String? _validationErrorKey() {
    if (_reasonTextEditingController.text.trim().isEmpty) {
      return pleaseEnterReasonKey;
    }
    if (_fromDate == null) {
      return pleaseSelectFromDateKey;
    }
    if (_toDate == null) {
      return pleaseSelectToDateKey;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      return toDateCannotBeBeforeFromDateKey;
    }
    //the school is already closed on every day picked, so there is nothing to
    //request leave for
    if (_workingDays.isEmpty) {
      return noLeaveRequiredForHolidayWeekendKey;
    }
    return null;
  }

  void _submitLeave() {
    final errorKey = _validationErrorKey();

    if (errorKey != null) {
      _showMessage(errorKey);
      return;
    }

    context.read<ApplyStudentLeaveCubit>().applyStudentLeave(
          childId: widget.childId,
          fromDate: DateFormat("yyyy-MM-dd").format(_fromDate!),
          toDate: DateFormat("yyyy-MM-dd").format(_toDate!),
          reason: _reasonTextEditingController.text.trim(),
          filePaths: _selectedFiles
              .where((file) => file.path != null)
              .map((file) => file.path!)
              .toList(),
        );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: child,
    );
  }

  Widget _buildReasonField() {
    return _buildFieldContainer(
      child: TextField(
        controller: _reasonTextEditingController,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: Utils.getTranslatedLabel(enterReasonForLeaveKey),
          hintStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({required bool isFromDate}) {
    final date = isFromDate ? _fromDate : _toDate;

    return GestureDetector(
      onTap: () => _pickDate(isFromDate: isFromDate),
      behavior: HitTestBehavior.opaque,
      child: _buildFieldContainer(
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null
                    ? Utils.getTranslatedLabel(
                        isFromDate ? fromDateKey : toDateKey,
                      )
                    : Utils.formatDayMonthYearWithWeekday(date),
                style: TextStyle(
                  color: date == null
                      ? Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.secondary,
                  fontSize: 14.0,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: 20.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Recap of the chosen range. Only rendered once both ends are picked so the
  /// parent can confirm the period before submitting. The count reflects the
  /// days the school is open, so weekly offs and public holidays inside the
  /// range are not presented as leave.
  Widget _buildLeaveSummary() {
    final calendarDays = _toDate!.difference(_fromDate!).inDays + 1;
    final totalDays = _workingDays.length;
    final excludedHolidays = calendarDays - totalDays;

    return Container(
      margin: const EdgeInsets.only(top: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: onlineClassCardColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 20.0,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  //formatted straight from the DateTime: serialising to a
                  //string only to parse it back is lossy and needless
                  _fromDate! == _toDate!
                      ? Utils.formatDayMonthYearFromDate(_fromDate!)
                      : "${Utils.formatDayMonthYearFromDate(_fromDate!)} – ${Utils.formatDayMonthYearFromDate(_toDate!)}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  "$totalDays ${Utils.getTranslatedLabel(totalDays == 1 ? leaveDayKey : leaveDaysKey)} • ${Utils.getTranslatedLabel(fullDayLeaveKey)}",
                  style: _labelTextStyle,
                ),
                //explains why the count is lower than the picked range
                if (excludedHolidays > 0) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    "$excludedHolidays ${Utils.getTranslatedLabel(holidayWeekendKey)} • ${Utils.getTranslatedLabel(workingDaysExcludeHolidaysKey)}",
                    style: _labelTextStyle.copyWith(color: leaveRejectedColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ApplyStudentLeaveCubit, ApplyStudentLeaveState>(
      builder: (context, state) {
        final inProgress = state is ApplyStudentLeaveInProgress;

        return Container(
          width: double.maxFinite,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(
            left: Utils.screenContentHorizontalPadding,
            right: Utils.screenContentHorizontalPadding,
            top: 12.0,
            bottom: MediaQuery.of(context).padding.bottom + 12.0,
          ),
          child: CustomRoundedButton(
            onTap: inProgress ? null : _submitLeave,
            height: 48.0,
            widthPercentage: 1.0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            buttonTitle: Utils.getTranslatedLabel(submitLeaveKey),
            showBorder: false,
            radius: 8.0,
            child: inProgress ? const CustomCircularProgressIndicator() : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildSubmitButton(),
      body: BlocListener<ApplyStudentLeaveCubit, ApplyStudentLeaveState>(
        listener: (context, state) {
          if (state is ApplyStudentLeaveSuccess) {
            Get.offNamed(Routes.studentLeaveSubmitted);
          }

          if (state is ApplyStudentLeaveFailure) {
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: Utils.getErrorMessageFromErrorCode(
                context,
                state.errorMessage,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 25.0,
                left: Utils.screenContentHorizontalPadding,
                right: Utils.screenContentHorizontalPadding,
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReasonField(),
                  _buildDateField(isFromDate: true),
                  _buildDateField(isFromDate: false),
                  AddFilesContainer(
                    fileNames: _selectedFiles.map((file) => file.name).toList(),
                    onTapAddFiles: _pickFiles,
                    onRemoveFile: (index) =>
                        setState(() => _selectedFiles.removeAt(index)),
                  ),
                  //rebuilds when the leave settings land, so the working day
                  //count reflects them even if the dates were picked first
                  if (_fromDate != null && _toDate != null)
                    BlocBuilder<LeaveSettingsCubit, LeaveSettingsState>(
                      builder: (context, state) => _buildLeaveSummary(),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: CustomAppBar(
                title: Utils.getTranslatedLabel(applyLeaveKey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
