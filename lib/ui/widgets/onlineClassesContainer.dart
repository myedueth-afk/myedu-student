import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/onlineClassesCubit.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/timeTableSlotCard.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Home screen section that lists today's online classes using the same
/// [TimeTableSlotCard] as the Time Table screen. The whole section hides itself
/// while loading, on error, or when there are no online classes today.
class OnlineClassesContainer extends StatelessWidget {
  final bool animate;

  ///When set (parent flow), "View All" opens that child's timetable; otherwise
  ///it opens the logged-in student's timetable.
  final int? childId;

  const OnlineClassesContainer({
    Key? key,
    this.animate = true,
    this.childId,
  }) : super(key: key);

  void _onTapViewAll() {
    if (childId != null) {
      Get.toNamed(Routes.childTimeTable, arguments: childId);
    } else {
      Get.toNamed(Routes.studentTimeTable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnlineClassesCubit, OnlineClassesState>(
      builder: (context, state) {
        if (state is! OnlineClassesFetchSuccess ||
            state.onlineClasses.isEmpty) {
          return const SizedBox();
        }

        ///Show only the first few here; "View All" leads to the full timetable.
        final onlineClasses = state.onlineClasses.length >
                numberOfOnlineClassesInHomeScreen
            ? state.onlineClasses.sublist(0, numberOfOnlineClassesInHomeScreen)
            : state.onlineClasses;

        return Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width *
                Utils.screenContentHorizontalPaddingInPercentage,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Utils.getTranslatedLabel(onlineClassesKey),
                    style: TextStyle(
                      color: Utils.getColorScheme(context).secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  InkWell(
                    onTap: _onTapViewAll,
                    child: Text(
                      Utils.getTranslatedLabel(viewAllKey),
                      style: TextStyle(
                        color: Utils.getColorScheme(context).onSurface,
                        fontSize: 13.0,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * (0.025),
              ),
              ...List.generate(
                onlineClasses.length,
                (index) => Animate(
                  effects: animate
                      ? listItemAppearanceEffects(
                          itemIndex: index,
                          totalLoadedItems: onlineClasses.length,
                        )
                      : null,
                  child: TimeTableSlotCard(
                    timeTableSlot: onlineClasses[index],
                    selectedDate: state.date,
                    backgroundColor: onlineClassCardColor,
                    variant: TimeTableSlotCardVariant.onlineClasses,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
