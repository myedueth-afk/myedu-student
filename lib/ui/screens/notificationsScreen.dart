import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/cubits/notificationsCubit.dart';
import 'package:eschool/data/repositories/notificationRepository.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return BlocProvider(
      create: (context) => NotificationsCubit(NotificationRepository()),
      child: NotificationsScreen(),
    );
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch notifications immediately on init
    Future.delayed(Duration.zero, () {
      context.read<NotificationsCubit>().fetchNotifications();
    });

    // Setup pagination listener
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.maxScrollExtent ==
        _scrollController.offset) {
      final notificationsCubit = context.read<NotificationsCubit>();
      if (notificationsCubit.hasMore()) {
        notificationsCubit.fetchMoreNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
            if (state is NotificationsFetchSuccess) {
              if (state.notifications.isEmpty) {
                return Align(
                    alignment: Alignment.center,
                    child: NoDataContainer(titleKey: noNotificationsKey));
              }
              return Align(
                alignment: Alignment.topCenter,
                child: RefreshIndicator(
                  displacement: Utils.getScrollViewTopPadding(
                      context: context,
                      appBarHeightPercentage:
                          Utils.appBarSmallerHeightPercentage),
                  onRefresh: () async {
                    context.read<NotificationsCubit>().fetchNotifications();
                  },
                  child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                          bottom: 25,
                          left: MediaQuery.of(context).size.width *
                              (Utils
                                  .screenContentHorizontalPaddingInPercentage),
                          right: MediaQuery.of(context).size.width *
                              (Utils
                                  .screenContentHorizontalPaddingInPercentage),
                          top: Utils.getScrollViewTopPadding(
                              context: context,
                              appBarHeightPercentage:
                                  Utils.appBarSmallerHeightPercentage)),
                      itemCount: state.notifications.length +
                          (state.fetchMoreNotificationsInProgress ||
                                  state.moreNotificationsFetchError
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator or error at the bottom
                        if (index >= state.notifications.length) {
                          if (state.fetchMoreNotificationsInProgress) {
                            return Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: CustomCircularProgressIndicator(
                                  indicatorColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          } else if (state.moreNotificationsFetchError) {
                            return Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Text(
                                      Utils.getTranslatedLabel(
                                          'errorLoadingMoreDataKey'),
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        context
                                            .read<NotificationsCubit>()
                                            .retryFetchMore();
                                      },
                                      icon: Icon(
                                        Icons.refresh,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      label: Text(
                                        Utils.getTranslatedLabel('retryKey'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }

                        final notification = state.notifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          width: MediaQuery.of(context).size.width * (0.85),
                          child: LayoutBuilder(
                            builder: (context, boxConstraints) {
                              final hasImage = notification.image != null &&
                                  notification.image!.isNotEmpty;
                              final heroTag =
                                  'notification-image-${notification.id}';

                              return Row(
                                children: [
                                  SizedBox(
                                    width: boxConstraints.maxWidth *
                                        (hasImage ? 0.725 : 1.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.title,
                                          style: TextStyle(
                                            height: 1.2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          notification.message,
                                          style: TextStyle(
                                            height: 1.2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          notification.createdAt,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.75),
                                            fontWeight: FontWeight.w400,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.start,
                                        )
                                      ],
                                    ),
                                  ),
                                  hasImage ? const Spacer() : const SizedBox(),
                                  hasImage
                                      ? Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            onTap: () {
                                              Utils.showImagePreview(
                                                context: context,
                                                imageUrl: notification.image!,
                                                heroTag: heroTag,
                                              );
                                            },
                                            child: SizedBox(
                                              width: boxConstraints.maxWidth *
                                                  (0.25),
                                              height: boxConstraints.maxWidth *
                                                  (0.25),
                                              child: Hero(
                                                tag: heroTag,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        notification.image!,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            Center(
                                                      child:
                                                          CustomCircularProgressIndicator(
                                                        indicatorColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                      ),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                      Icons.error,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox()
                                ],
                              );
                            },
                          ),
                        );
                      }),
                ),
              );
            }
            if (state is NotificationsFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  onTapRetry: () {
                    context.read<NotificationsCubit>().fetchNotifications();
                  },
                ),
              );
            }
            return Center(
              child: CustomCircularProgressIndicator(
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(title: notificationsKey),
          ),
        ],
      ),
    );
  }
}
