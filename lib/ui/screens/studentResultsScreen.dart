import 'package:eschool/cubits/resultsCubit.dart';
import 'package:eschool/cubits/schoolSessionYearsCubit.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/resultsContainer.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Standalone results screen for students, navigated to directly from
/// the Subject-Wise Detailed Report screen.
/// Provides the required Cubits and overlays a back button so the student
/// can return to the previous screen.
class StudentResultsScreen extends StatelessWidget {
  const StudentResultsScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ResultsCubit>(
          create: (_) => ResultsCubit(StudentRepository()),
        ),
        BlocProvider<SchoolSessionYearsCubit>(
          create: (_) => SchoolSessionYearsCubit(SchoolRepository()),
        ),
      ],
      child: const StudentResultsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ResultsContainer renders its own full-screen header + content.
          // childId and subjects are omitted → student's own results are fetched.
          const ResultsContainer(),

          // Overlay a back button because ResultsContainer hides it for students
          // (it is normally embedded in the home screen where no back is needed).
          CustomBackButton(
            topPadding: MediaQuery.of(context).padding.top +
                Utils.appBarContentTopPadding,
          ),
        ],
      ),
    );
  }
}
