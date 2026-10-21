import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/slidersCubit.dart';
import 'package:eschool/cubits/socketSettingCubit.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/home/widgets/homeContainerTopProfileContainer.dart';
import 'package:eschool/ui/widgets/appUnderMaintenanceContainer.dart';
import 'package:eschool/ui/widgets/borderedProfilePictureContainer.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/forceUpdateDialogContainer.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/notificationUtility.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();

  static Widget routeInstance() {
    return BlocProvider<SlidersCubit>(
      create: (context) => SlidersCubit(SchoolRepository()),
      child: const ParentHomeScreen(),
    );
  }
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with WidgetsBindingObserver {
  var canPop = false;

  /// Returns true if the parent has at least one child assigned.
  bool _hasChildren() {
    final children = context.read<AuthCubit>().getParentDetails().children;
    return children != null && children.isNotEmpty;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () {
      _fetchSchoolConfiguration();
      NotificationUtility.setUpNotificationService();
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background, recheck notification permissions
    // This handles the case where user manually enables notifications in Settings
    if (state == AppLifecycleState.resumed) {
      NotificationUtility.recheckNotificationPermissions();

      // Reconnect WebSocket to pick up messages sent while app was in background
      if (_hasChildren() &&
          Utils.isModuleEnabled(
              context: context, moduleId: chatModuleId.toString())) {
        context.read<SocketSettingCubit>().reconnect();
      }
    }
  }

  void _fetchSchoolConfiguration() {
    if (!_hasChildren()) return;

    final firstChildId =
        context.read<AuthCubit>().getParentDetails().children!.first.id ?? 0;
    context
        .read<SchoolConfigurationCubit>()
        .fetchSchoolConfiguration(useParentApi: true, childId: firstChildId);
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: ScreenTopBackgroundContainer(
        padding: EdgeInsets.zero,
        heightPercentage: Utils.appBarMediumtHeightPercentage,
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Stack(
              children: [
                //Bordered circles
                PositionedDirectional(
                  top: MediaQuery.of(context).size.width * (-0.2),
                  start: MediaQuery.of(context).size.width * (-0.225),
                  child: Container(
                    padding: const EdgeInsetsDirectional.only(
                        end: 20.0, bottom: 20.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                      ),
                      shape: BoxShape.circle,
                    ),
                    width: MediaQuery.of(context).size.width * (0.6),
                    height: MediaQuery.of(context).size.width * (0.6),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.1),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                //bottom fill circle
                PositionedDirectional(
                  bottom: MediaQuery.of(context).size.width * (-0.15),
                  end: MediaQuery.of(context).size.width * (-0.15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    width: MediaQuery.of(context).size.width * (0.4),
                    height: MediaQuery.of(context).size.width * (0.4),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsetsDirectional.only(
                      end: boxConstraints.maxWidth * (0.02),
                      start: boxConstraints.maxWidth * (0.056),
                      bottom: boxConstraints.maxHeight * (0.21),
                    ),
                    child: Row(
                      children: [
                        BorderedProfilePictureContainer(
                          heightAndWidth: 65,
                          onTap: () {
                            Get.toNamed(Routes.parentProfile);
                          },
                          imageUrl: context
                                  .read<AuthCubit>()
                                  .getParentDetails()
                                  .image ??
                              "",
                        ),
                        SizedBox(
                          width: boxConstraints.maxWidth * (0.04),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: boxConstraints.maxWidth * (0.5),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context
                                        .read<AuthCubit>()
                                        .getParentDetails()
                                        .getFullName(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                  Text(
                                    context
                                            .read<AuthCubit>()
                                            .getParentDetails()
                                            .email ??
                                        "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                        const Spacer(),
                        BlocBuilder<AppConfigurationCubit,
                            AppConfigurationState>(
                          builder: (context, state) {
                            return Utils.isModuleEnabled(
                                    context: context,
                                    moduleId: chatModuleId.toString())
                                ? SvgButton(
                                    onTap: () {
                                      Get.toNamed(Routes.chatContacts);
                                    },
                                    svgIconUrl:
                                        Utils.getImagePath("chat_icon.svg"),
                                  )
                                : const SizedBox();
                          },
                        ),
                        IconButton(
                          iconSize: 24,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          onPressed: () {
                            Get.toNamed(Routes.settings);
                          },
                          icon: const Icon(Icons.settings),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChildDetailsContainer({
    required double width,
    required Student student,
  }) {
    return Animate(
      effects: customItemZoomAppearanceEffects(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Get.toNamed(Routes.parentChildDetails, arguments: student);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          width: width,
          height: 150, //200
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: boxConstraints.maxHeight * (0.125),
                          ),
                          BorderedProfilePictureContainer(
                            onTap: () {
                              Get.toNamed(
                                Routes.parentChildDetails,
                                arguments: student,
                              );
                            },
                            heightAndWidth: 50,
                            imageUrl: student.childUserDetails?.image ?? "",
                          ),
                          SizedBox(
                            height: boxConstraints.maxHeight * (0.075),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: Text(
                              student.getFullName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: boxConstraints.maxHeight * (0.025),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.5),
                            child: Text(
                              "${Utils.getTranslatedLabel(classKey)} - ${student.classSection?.fullName}",
                              style: TextStyle(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: -15,
                    start: (boxConstraints.maxWidth * 0.5) - 15,
                    child: Container(
                      alignment: Alignment.center,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.3),
                            offset: const Offset(0, 5),
                            blurRadius: 20,
                          )
                        ],
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenContainer() {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * (0.075),
        right: MediaQuery.of(context).size.width * (0.075),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              Utils.getTranslatedLabel(myChildrenKey),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          LayoutBuilder(
            builder: (context, boxConstraints) {
              return Wrap(
                spacing: boxConstraints.maxWidth * (0.05),
                runSpacing: 32.5,
                children:
                    (context.read<AuthCubit>().getParentDetails().children ??
                            [])
                        .map(
                          (student) => _buildChildDetailsContainer(
                            width: boxConstraints.maxWidth * (0.45),
                            student: student,
                          ),
                        )
                        .toList(),
              );
            },
          )
        ],
      ),
    );
  }

  void _onWillPop() {
    setState(() {
      canPop = true;
    });
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel(pressbackagaintoexitKey),
      backgroundColor: Theme.of(context).colorScheme.error,
    ); // Do not exit the app
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        canPop = false;
      });
    });
  }

  Future<void> _refreshParentData() async {
    try {
      // Call the new API to get updated parent data
      await context.read<AuthCubit>().updateParentDetails();

      if (mounted) setState(() {});

      if (!_hasChildren()) return;

      // Refresh school configuration to get latest data
      final firstChildId =
          context.read<AuthCubit>().getParentDetails().children!.first.id ?? 0;

      await context.read<SchoolConfigurationCubit>().fetchSchoolConfiguration(
            useParentApi: true,
            childId: firstChildId,
          );
    } catch (e) {
      if (mounted) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage: e.toString(),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Widget _buildAppBarShimmer() {
    final width = MediaQuery.of(context).size.width;
    return ShimmerLoadingContainer(
      child: Container(
        width: width,
        height: MediaQuery.of(context).size.height *
            Utils.appBarMediumtHeightPercentage,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsetsDirectional.only(
          start: width * 0.056,
          end: width * 0.02,
          top: MediaQuery.of(context).padding.top + 10,
        ),
        child: Row(
          children: [
            CustomShimmerContainer(
              width: 65,
              height: 65,
              borderRadius: 32.5,
            ),
            SizedBox(width: width * 0.04),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmerContainer(
                  width: width * 0.35,
                  height: 18,
                  borderRadius: 4,
                ),
                const SizedBox(height: 10),
                CustomShimmerContainer(
                  width: width * 0.45,
                  height: 12,
                  borderRadius: 3,
                ),
              ],
            ),
            const Spacer(),
            CustomShimmerContainer(
              width: 24,
              height: 24,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            CustomShimmerContainer(
              width: 24,
              height: 24,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenShimmer() {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.075),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, boxConstraints) {
              return Wrap(
                spacing: boxConstraints.maxWidth * 0.05,
                runSpacing: 32.5,
                children: List.generate(
                  4,
                  (index) => ShimmerLoadingContainer(
                    child: CustomShimmerContainer(
                      width: boxConstraints.maxWidth * 0.45,
                      height: 150,
                      borderRadius: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAppBarShimmer(),
          const SizedBox(height: 25),
          _buildChildrenShimmer(),
        ],
      ),
    );
  }

  Widget _buildNoChildrenScreen() {
    return RefreshIndicator(
      onRefresh: _refreshParentData,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      edgeOffset: MediaQuery.of(context).size.height *
          Utils.appBarMediumtHeightPercentage,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
              ),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: NoDataContainer(
                  titleKey: noChildrenFoundKey,
                ),
              ),
            ),
          ),
          _buildAppBar(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        _onWillPop();
      },
      child: Scaffold(
        body: context.read<AppConfigurationCubit>().appUnderMaintenance() ||
                context.read<AppConfigurationCubit>().systemUnderMaintenance()
            ? const AppUnderMaintenanceContainer()
            : !_hasChildren()
                ? _buildNoChildrenScreen()
                : BlocConsumer<SchoolConfigurationCubit,
                    SchoolConfigurationState>(
                    listener: (context, state) {
                      if (state is SchoolConfigurationFetchSuccess) {
                        if (Utils.isModuleEnabled(
                            context: context,
                            moduleId: chatModuleId.toString())) {
                          context.read<SocketSettingCubit>().init(
                              userId: context
                                      .read<AuthCubit>()
                                      .getParentDetails()
                                      .id ??
                                  0);
                        }

                        // Process pending notification after app is fully initialized
                        // This handles notifications when app was opened from terminated state
                        if (NotificationUtility.hasPendingNotification) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            NotificationUtility.processPendingNotification();
                          });
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is SchoolConfigurationFetchSuccess) {
                        return RefreshIndicator(
                          onRefresh: _refreshParentData,
                          color: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          edgeOffset: MediaQuery.of(context).size.height *
                              Utils.appBarMediumtHeightPercentage,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: 50,
                                    top: Utils.getScrollViewTopPadding(
                                      context: context,
                                      appBarHeightPercentage:
                                          Utils.appBarMediumtHeightPercentage,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildChildrenContainer(),
                                    ],
                                  ),
                                ),
                              ),
                              _buildAppBar(),
                              //Check force update here
                              context
                                      .read<AppConfigurationCubit>()
                                      .forceUpdate()
                                  ? FutureBuilder<bool>(
                                      future: Utils.forceUpdate(
                                        context
                                            .read<AppConfigurationCubit>()
                                            .getAppVersion(),
                                      ),
                                      builder: (context, snaphsot) {
                                        if (snaphsot.hasData) {
                                          return (snaphsot.data ?? false)
                                              ? const ForceUpdateDialogContainer()
                                              : const SizedBox();
                                        }

                                        return const SizedBox();
                                      },
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        );
                      }

                      if (state is SchoolConfigurationFetchFailure) {
                        return Center(
                          child: Column(
                            children: [
                              HomeContainerTopProfileContainer(),
                              const SizedBox(height: 15),
                              ErrorContainer(
                                errorMessageCode: state.errorMessage,
                                onTapRetry: _fetchSchoolConfiguration,
                              ),
                              const SizedBox(height: 20),
                              CustomRoundedButton(
                                height: 40,
                                widthPercentage: 0.3,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                onTap: () {
                                  Get.toNamed(Routes.settings);
                                },
                                titleColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                buttonTitle:
                                    Utils.getTranslatedLabel(settingsKey),
                                showBorder: false,
                              )
                            ],
                          ),
                        );
                      }

                      // Initial loading state - show shimmer
                      return _buildShimmerLoading();
                    },
                  ),
      ),
    );
  }
}
