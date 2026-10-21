import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/transportPlanHistoryCubit.dart';
import 'package:eschool/data/models/transportPlanDetails.dart';
import 'package:eschool/data/repositories/transportRepository.dart';
import 'package:eschool/ui/screens/parentTransportEnroll/transportHome/widgets/commonTransportWidgets.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/htmlPrintMixin.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TransportPlanHistoryScreen extends StatefulWidget {
  final int? studentId;

  const TransportPlanHistoryScreen({super.key, this.studentId});

  static Widget getRouteInstance() {
    final int? studentId = Get.arguments as int?;
    return BlocProvider(
      create: (context) => TransportPlanHistoryCubit(),
      child: TransportPlanHistoryScreen(studentId: studentId),
    );
  }

  @override
  State<TransportPlanHistoryScreen> createState() =>
      _TransportPlanHistoryScreenState();
}

class _TransportPlanHistoryScreenState extends State<TransportPlanHistoryScreen>
    with HtmlPrintMixin {
  final TransportRepository _transportRepository = TransportRepository();

  int _loadingPlanId = -1;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  void _fetchPlans() {
    if (widget.studentId == null) return;
    context
        .read<TransportPlanHistoryCubit>()
        .fetchPlans(userId: widget.studentId!);
  }

  Future<void> _downloadReceipt(TransportPlanDetails plan) async {
    if (_loadingPlanId != -1) return;

    final planId = plan.id ?? plan.paymentId;
    if (planId == null) return;

    setState(() => _loadingPlanId = planId);

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
      setState(() => _loadingPlanId = -1);
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
              if (mounted) setState(() => _loadingPlanId = -1);
            },
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                const CustomAppBar(
                  title: planHistoryKey,
                  showBackButton: true,
                ),
                Expanded(
                  child: BlocBuilder<TransportPlanHistoryCubit,
                      TransportPlanHistoryState>(
                    builder: (context, state) {
                      if (state is TransportPlanHistoryFetchInProgress) {
                        return _buildLoadingState();
                      }

                      if (state is TransportPlanHistoryFetchFailure) {
                        return ErrorContainer(
                          errorMessageCode: state.errorMessage,
                          onTapRetry: _fetchPlans,
                        );
                      }

                      if (state is TransportPlanHistoryFetchSuccess) {
                        if (state.plans.isEmpty) {
                          return Center(
                            child: NoDataContainer(titleKey: noDataFoundKey),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: () async => _fetchPlans(),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                EdgeInsets.all(appContentHorizontalPadding),
                            itemCount: state.plans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) => _PlanHistoryCard(
                              plan: state.plans[index],
                              studentId: widget.studentId,
                              isLoading: _loadingPlanId ==
                                  (state.plans[index].id ??
                                      state.plans[index].paymentId),
                              onDownload: () =>
                                  _downloadReceipt(state.plans[index]),
                            ),
                          ),
                        );
                      }

                      return _buildLoadingState();
                    },
                  ),
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
      padding: EdgeInsets.all(appContentHorizontalPadding),
      child: Column(
        children: List.generate(
          3,
          (i) => ShimmerLoadingContainer(
            child: CustomShimmerContainer(
              height: 180,
              width: double.infinity,
              borderRadius: 8,
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanHistoryCard extends StatelessWidget {
  final TransportPlanDetails plan;
  final int? studentId;
  final bool isLoading;
  final VoidCallback onDownload;

  const _PlanHistoryCard({
    required this.plan,
    required this.studentId,
    required this.isLoading,
    required this.onDownload,
  });

  ({Color background, Color foreground}) _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return (
          background: const Color(0xFFDFF6E2),
          foreground: const Color(0xFF37C748),
        );
      case 'inactive':
        return (
          background: const Color(0xFFFFF2E8),
          foreground: const Color(0xFFFF8C00),
        );
      case 'expired':
        return (
          background: const Color(0xFFFFE8E8),
          foreground: const Color(0xFFE53935),
        );
      default:
        return (
          background: const Color(0xFFE0EDF6),
          foreground: const Color(0xFF29638A),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planId = plan.id ?? plan.paymentId;

    final bool isPending =
        plan.status != null && plan.status!.toLowerCase() != 'paid';
    final bool isActive =
        !isPending && plan.planStatus?.toLowerCase() == 'active';
    final bool isExpiring =
        isActive && plan.expiresInDays != null && plan.expiresInDays! <= 7;

    final String? displayStatus = isPending ? pendingKey : plan.planStatus;
    final statusColor = isPending
        ? (
            background: const Color(0xFFFFF2E8),
            foreground: const Color(0xFFFF8C00),
          )
        : _getStatusColor(plan.planStatus);
    final statusLabel = displayStatus != null
        ? displayStatus.substring(0, 1).toUpperCase() +
            displayStatus.substring(1)
        : null;

    return EnrollCard(
      onTap: isActive
          ? () => Get.toNamed(Routes.transportPlanDetailsScreen,
              arguments: studentId)
          : null,
      title: transportationPlanKey,
      trailing: statusLabel != null
          ? EnrollStatusChip(
              title: statusLabel,
              background: statusColor.background,
              foreground: statusColor.foreground,
            )
          : const SizedBox.shrink(),
      children: [
        LabelValue(
          label: planKey,
          value: plan.duration ?? 'N/A',
        ),
        LabelValue(
          label: validityKey,
          value: plan.validityPeriod,
        ),
        LabelValue(
          label: routeNameKey,
          value: plan.route?.name ?? 'N/A',
          addBottomSpacing: !isActive,
        ),
        if (isExpiring) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.toNamed(
              Routes.planRenewalScreen,
              arguments: {'userId': studentId},
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE8E8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utils.getTranslatedLabel(planExpiringTitleKey),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Utils.getTranslatedLabel(yourPlanWillExpireInKey)} ${plan.expiresInDays} ${Utils.getTranslatedLabel(daysKey)}.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.surface,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!isActive && planId != null) ...[
          const SizedBox(height: 12),
          DottedDownloadButton(
            labelKey: downloadInvoiceKey,
            isLoading: isLoading,
            onTap: onDownload,
          ),
        ],
      ],
    );
  }
}
