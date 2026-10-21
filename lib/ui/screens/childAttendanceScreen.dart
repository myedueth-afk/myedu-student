import 'package:eschool/cubits/attendanceCubit.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/attendanceContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChildAttendanceScreen extends StatelessWidget {
  final int childId;
  const ChildAttendanceScreen({Key? key, required this.childId})
      : super(key: key);

  static Widget routeInstance() {
    // Handle both cases: when arguments is passed as int directly or as a Map
    final arguments = Get.arguments;
    int childId = 0;

    if (arguments is int) {
      // Direct int argument
      childId = arguments;
    } else if (arguments is Map<String, dynamic>) {
      // Map argument
      childId = arguments['childId'] ?? 0;
    }

    return BlocProvider<AttendanceCubit>(
      create: (context) => AttendanceCubit(StudentRepository()),
      child: ChildAttendanceScreen(
        childId: childId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AttendanceContainer(
        childId: childId,
      ),
    );
  }
}
