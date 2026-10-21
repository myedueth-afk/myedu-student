import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/cancelStudentLeaveCubit.dart';
import 'package:eschool/cubits/studentLeavesCubit.dart';
import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/filterSelectionBottomsheet.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/studentLeaveCard.dart';
import 'package:eschool/ui/widgets/studentLeaveDetailsBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class StudentLeavesScreen extends StatefulWidget {
  final int childId;

  const StudentLeavesScreen({Key? key, required this.childId})
      : super(key: key);

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StudentLeavesCubit>(
          create: (_) => StudentLeavesCubit(StudentLeaveRepository()),
        ),
        BlocProvider<CancelStudentLeaveCubit>(
          create: (_) => CancelStudentLeaveCubit(StudentLeaveRepository()),
        ),
      ],
      child: StudentLeavesScreen(childId: Get.arguments as int),
    );
  }

  @override
  State<StudentLeavesScreen> createState() => _StudentLeavesScreenState();
}

class _StudentLeavesScreenState extends State<StudentLeavesScreen> {
  /// null means "All", otherwise only leaves with this status are listed.
  StudentLeaveStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchLeaves);
  }

  void _fetchLeaves() {
    context.read<StudentLeavesCubit>().fetchStudentLeaves(
          childId: widget.childId,
        );
  }

  List<StudentLeave> _applyFilter(List<StudentLeave> leaves) {
    if (_selectedStatus == null) {
      return leaves;
    }
    return leaves
        .where((leave) => leave.leaveStatus == _selectedStatus)
        .toList();
  }

  String _statusLabel(StudentLeaveStatus? status) {
    switch (status) {
      case StudentLeaveStatus.pending:
        return Utils.getTranslatedLabel(pendingKey);
      case StudentLeaveStatus.approved:
        return Utils.getTranslatedLabel(acceptedKey);
      case StudentLeaveStatus.rejected:
        return Utils.getTranslatedLabel(rejectedKey);
      case null:
        return Utils.getTranslatedLabel(allKey);
    }
  }

  void _showStatusFilter() {
    const statuses = <StudentLeaveStatus?>[
      null,
      StudentLeaveStatus.pending,
      StudentLeaveStatus.approved,
      StudentLeaveStatus.rejected,
    ];

    final labels = statuses.map(_statusLabel).toList();

    Utils.showBottomSheet(
      context: context,
      child: FilterSelectionBottomsheet<String>(
        titleKey: statusKey,
        values: labels,
        selectedValue: _statusLabel(_selectedStatus),
        onSelection: (value) {
          Get.back();
          final index = labels.indexOf(value ?? "");
          if (index != -1) {
            setState(() => _selectedStatus = statuses[index]);
          }
        },
      ),
    );
  }

  void _showLeaveDetails(StudentLeave leave) {
    Utils.showBottomSheet(
      context: context,
      child: StudentLeaveDetailsBottomsheet(
        leave: leave,
        onTapCancelRequest: leave.id == null
            ? null
            : () {
                Get.back();
                context
                    .read<CancelStudentLeaveCubit>()
                    .cancelStudentLeave(leaveId: leave.id!);
              },
      ),
    );
  }

  Future<void> _openApplyLeave() async {
    await Get.toNamed(Routes.applyStudentLeave, arguments: widget.childId);

    //the apply screen swaps itself for the success screen once the request goes
    //through, so refetching whenever it leaves keeps the list current either way
    if (mounted) {
      _fetchLeaves();
    }
  }

  Widget _buildLeaves() {
    return BlocBuilder<StudentLeavesCubit, StudentLeavesState>(
      builder: (context, state) {
        if (state is StudentLeavesFetchSuccess) {
          final leaves = _applyFilter(state.leaves);

          if (leaves.isEmpty) {
            return Align(
              alignment: Alignment.center,
              child: NoDataContainer(titleKey: noLeavesFoundKey),
            );
          }

          return CustomRefreshIndicator(
            displacment: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
            ),
            onRefreshCallback: () async => _fetchLeaves(),
            child: ListView.builder(
              itemCount: leaves.length,
              padding: EdgeInsets.only(
                bottom: 100.0,
                left: Utils.screenContentHorizontalPadding,
                right: Utils.screenContentHorizontalPadding,
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              itemBuilder: (context, index) => StudentLeaveCard(
                leave: leaves[index],
                onTap: () => _showLeaveDetails(leaves[index]),
              ),
            ),
          );
        }

        if (state is StudentLeavesFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              animate: true,
              onTapRetry: _fetchLeaves,
            ),
          );
        }

        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openApplyLeave,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      body: BlocListener<CancelStudentLeaveCubit, CancelStudentLeaveState>(
        listener: (context, state) {
          if (state is CancelStudentLeaveSuccess) {
            //drop it locally first so the list updates even if the refetch lags
            context
                .read<StudentLeavesCubit>()
                .removeLeave(leaveId: state.leaveId);
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: Utils.getTranslatedLabel(leaveRequestCancelledKey),
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
            );
            _fetchLeaves();
          }

          if (state is CancelStudentLeaveFailure) {
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
            _buildLeaves(),
            Align(
              alignment: Alignment.topCenter,
              child: CustomAppBar(
                title: Utils.getTranslatedLabel(leavesKey),
                trailingWidget: GestureDetector(
                  onTap: _showStatusFilter,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
