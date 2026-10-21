import 'package:eschool/cubits/timeTableCubit.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/timetableContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Standalone Time Table screen for the logged-in student. Reuses
/// [TimeTableContainer], which already defaults to the current weekday, so it
/// opens on today. Pushed from the home "Online Classes" -> "View All".
class StudentTimeTableScreen extends StatelessWidget {
  const StudentTimeTableScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<TimeTableCubit>(
      create: (context) => TimeTableCubit(StudentRepository()),
      child: const StudentTimeTableScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TimeTableContainer(showBackButton: true),
    );
  }
}
