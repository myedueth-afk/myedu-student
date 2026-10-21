import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/transportPlanDetailsCubit.dart';
import 'package:eschool/data/repositories/transportRepository.dart';
import 'package:eschool/ui/screens/parentTransportEnroll/transportHome/widgets/commonTransportWidgets.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/htmlPrintMixin.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TransportPlanDetailsScreen extends StatefulWidget {
  final int? studentId;

  const TransportPlanDetailsScreen({super.key, this.studentId});

  static Widget getRouteInstance() {
    final int? studentId = Get.arguments as int?;
    return BlocProvider(
      create: (context) => TransportPlanDetailsCubit(),
      child: TransportPlanDetailsScreen(studentId: studentId),
    );
  }

  @override
  State<TransportPlanDetailsScreen> createState() =>
      _TransportPlanDetailsScreenState();
}

class _TransportPlanDetailsScreenState extends State<TransportPlanDetailsScreen>
    with HtmlPrintMixin {
  final TransportRepository _transportRepository = TransportRepository();
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlanDetails();
  }

  void _fetchPlanDetails() {
    final userId = widget.studentId;
    if (userId == null) {
      debugPrint("Error: No valid student ID found for transport plan details");
      return;
    }
    context.read<TransportPlanDetailsCubit>().fetchPlanDetails(userId: userId);
  }

  Future<void> _downloadReceipt() async {
    if (_isDownloading) return;

    final planDetails =
        context.read<TransportPlanDetailsCubit>().getPlanDetails();
    final planId = planDetails?.id ?? planDetails?.paymentId;
    if (planId == null) return;

    setState(() => _isDownloading = true);

    try {
      final html = await _transportRepository.getTransportReceipt(id: planId);
      if (!mounted) return;
      await schedulePrint(
        html: html,
        fileName: 'transport_receipt_$planId',
        jobName: 'transport_receipt_$planId',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(failedToDownloadKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          buildHiddenPrintWebView(
            onPrintDispatched: () {
              if (mounted) setState(() => _isDownloading = false);
            },
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const CustomAppBar(
                  title: transportationKey,
                  showBackButton: true,
                ),
                Expanded(
                  child: BlocBuilder<TransportPlanDetailsCubit,
                      TransportPlanDetailsState>(
                    builder: (context, state) {
                      if (state is TransportPlanDetailsFetchInProgress) {
                        return _buildLoadingState();
                      }

                      if (state is TransportPlanDetailsNoData) {
                        return Center(
                          child: NoDataContainer(
                            titleKey: noTransportAssignedKey,
                          ),
                        );
                      }

                      if (state is TransportPlanDetailsFetchFailure) {
                        return ErrorContainer(
                          errorMessageCode: state.errorMessage,
                          onTapRetry: _fetchPlanDetails,
                        );
                      }

                      if (state is TransportPlanDetailsFetchSuccess) {
                        return _buildPlanDetailsContent(state.planDetails);
                      }

                      return _buildLoadingState();
                    },
                  ),
                ),
                BlocBuilder<TransportPlanDetailsCubit,
                    TransportPlanDetailsState>(
                  builder: (context, state) {
                    if (state is TransportPlanDetailsFetchSuccess) {
                      return _buildBottomButtons();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: appContentHorizontalPadding,
        vertical: 16,
      ),
      child: Column(
        children: [
          ShimmerLoadingContainer(
            child: CustomShimmerContainer(
              height: 200,
              width: double.infinity,
              borderRadius: 12,
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
          ShimmerLoadingContainer(
            child: CustomShimmerContainer(
              height: 200,
              width: double.infinity,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetailsContent(planDetails) {
    return RefreshIndicator(
      onRefresh: () async => _fetchPlanDetails(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 860;
            final double gap = isWide ? 20.0 : 14.0;

            final Widget routePickupSection = _SectionCard(
              title: ' Route & Pickup Details',
              children: [
                LabelValue(
                  label: 'Route Name',
                  value: planDetails.route?.name ?? 'Not specified',
                  addTopSpacing: false,
                ),
                LabelValue(
                  label: 'Pickup Location',
                  value: planDetails.pickupStop?.name ?? 'Not specified',
                ),
                LabelValue(
                  label: 'Shift',
                  value: planDetails.shiftDetails,
                ),
                LabelValue(
                  label: 'Pickup Time',
                  value: planDetails.pickupTimeFormatted,
                  addBottomSpacing: false,
                ),
              ],
            );

            final Widget planSection = _SectionCard(
              title: ' Plan Details',
              children: [
                LabelValue(
                  label: 'Plan',
                  value: planDetails.duration ?? 'Not specified',
                  addTopSpacing: false,
                ),
                LabelValue(
                  label: 'Validity',
                  value: planDetails.validityPeriod,
                ),
                LabelValue(
                  label: 'Total Fee',
                  value: planDetails.totalFee ?? 'Not specified',
                ),
                LabelValue(
                  label: 'Payment Mode',
                  value: planDetails.paymentModeFormatted,
                  addBottomSpacing: false,
                ),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  routePickupSection,
                  SizedBox(height: gap),
                  planSection,
                  SizedBox(height: gap),
                  const SizedBox(height: 8),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: routePickupSection),
                    SizedBox(width: gap),
                    Expanded(child: planSection),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(appContentHorizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomRoundedButton(
                onTap: _isDownloading ? null : _downloadReceipt,
                backgroundColor: Colors.white,
                showBorder: true,
                borderColor: Theme.of(context).colorScheme.primary,
                titleColor: Theme.of(context).colorScheme.primary,
                buttonTitle: downloadInvoiceKey,
                widthPercentage: 1.0,
                height: 50,
                radius: 12,
                textSize: 15,
                fontWeight: FontWeight.w600,
                child: _isDownloading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomRoundedButton(
                onTap: () {
                  Get.toNamed(Routes.busRouteScreen, arguments: {
                    'studentId': widget.studentId,
                    'planDetails': context
                        .read<TransportPlanDetailsCubit>()
                        .getPlanDetails(),
                  });
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                titleColor: Colors.white,
                buttonTitle: busRouteKey,
                showBorder: false,
                widthPercentage: 1.0,
                height: 50,
                radius: 12,
                textSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomTextContainer(
            textKey: title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        EnrollCard(
          title: '',
          trailing: const SizedBox(),
          showHeader: false,
          children: children,
        ),
      ],
    );
  }
}
