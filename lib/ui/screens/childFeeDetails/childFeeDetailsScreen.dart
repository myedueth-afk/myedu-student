import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/childFeeCubit.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/cubits/downloadFeeReceiptCubit.dart';
import 'package:eschool/cubits/latestPaymentTransactionCubit.dart';
import 'package:eschool/cubits/prePaymentTasksCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/classFeeType.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/manualFeePaymentArguments.dart';
import 'package:eschool/data/models/paymentGateway.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/data/repositories/paymentRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/advanceInstallmentAmountBottomsheet.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/downloadReceiptDialog.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeDetailsMenuBottomsheet.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeInformationContainer.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeReliefContainer.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/installments.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/pendingTransactionWarningDialog.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/rejectedPaymentBottomsheet.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/selectFeePaymentMethodBottomsheet.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/selectPaymentMethodBottomsheet.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTabBarContainer.dart';
import 'package:eschool/ui/widgets/rejectedPaymentBanner.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/tabBarBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/paymentGatewayService.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ChildFeeDetailsScreen extends StatefulWidget {
  /// The copy the list had, used only to seed [ChildFeeCubit] so there is
  /// something to draw before this screen's own read comes back.
  ///
  /// Nothing should read it directly — it stops being true the moment the
  /// school touches the fee. Read [_ChildFeeDetailsScreenState._fee] instead.
  final ChildFeeDetails childFeeDetails;
  final Student child;
  ChildFeeDetailsScreen(
      {Key? key, required this.childFeeDetails, required this.child})
      : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    final childFeeDetails = arguments['childFeeDetails'] as ChildFeeDetails;
    final child = arguments['child'] as Student;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PrePaymentTasksCubit(),
        ),
        BlocProvider(
            create: (context) =>
                LatestPaymentTransactionCubit(PaymentRepository())),
        //seeded so the screen draws before its own read comes back
        BlocProvider(
          create: (context) => ChildFeeCubit(
            FeeRepository(),
            fee: childFeeDetails,
            childId: child.id ?? 0,
          ),
        ),
      ],
      child: ChildFeeDetailsScreen(
        childFeeDetails: childFeeDetails,
        child: child,
      ),
    );
  }

  @override
  State<ChildFeeDetailsScreen> createState() => _ChildFeeDetailsScreenState();
}

class _ChildFeeDetailsScreenState extends State<ChildFeeDetailsScreen> {
  late String _currentlySelectedTabKey = compulsoryTitleKey;
  late List<int> _toPayOptionalFeeIds = [];
  late bool _enablePayInInstallments = false;
  late bool showPendingTransactionDialog = true;
  late double _advanceAmount = 0.0;

  ///[Which side of the fee the parent is looking at]
  bool get _isCompulsoryTabSelected =>
      _currentlySelectedTabKey == compulsoryTitleKey;

  /// The fee as it currently stands — from [ChildFeeCubit], not the route
  /// arguments, which were only true when the list was loaded.
  ///
  /// A [BlocBuilder] around the body rebuilds everything below when it changes.
  ChildFeeDetails get _fee => context.read<ChildFeeCubit>().state.fee;

  /// Whether the compulsory fee is being settled in installments — the parent
  /// turning the toggle on, or a payment already filed against an installment.
  ///
  /// The single answer the whole compulsory tab reads. The toggle alone cannot
  /// carry it: it is state of one visit to this screen, and it is gone by the
  /// time the parent comes back from submitting a payment.
  bool get _isInInstallmentMode =>
      _enablePayInInstallments || _fee.isBeingPaidInInstallments();

  /// Whether an unconfirmed payment stands the pay section down on this tab.
  ///
  /// A compulsory fee is paid as one thing, so anything outstanding against it
  /// blocks the lot. Optional fees are picked and paid one at a time, each with
  /// its own payment: one under review is marked on its own row, and the
  /// section only stands down once nothing is left to pick.
  bool get _payingIsBlockedByAnUnconfirmedPayment {
    final fee = _fee;

    if (_isCompulsoryTabSelected) {
      return fee.hasPendingPayment(compulsory: true);
    }

    return fee.hasPendingPayment(compulsory: false) &&
        !fee.hasPayableOptionalFee();
  }

  final Razorpay _razorpay = Razorpay();
  PaymentGatewayService? _paymentGatewayService;

  /// Returns the date exactly as received from the API — no conversion.
  String _formatOptionalPaidDate(String? dateString) {
    return dateString ?? "";
  }

  @override
  void initState() {
    super.initState();
    // PaymentGatewayService will be initialized when needed in didChangeDependencies

    //the copy the list handed over is as old as the list, so the fee is
    //re-read on opening rather than only when the parent pulls for it
    _refreshFee();
  }

  ///[Re-reads the fee behind this screen]
  Future<void> _refreshFee() => context.read<ChildFeeCubit>().refresh();

  /// Keeps everything that depends on the fee in step with a fresh copy of it.
  void _childFeeListener(BuildContext context, ChildFeeState state) {
    if (state.refreshInProgress) {
      return;
    }

    if (state.refreshError != null) {
      //the last good copy is still on screen, so this reports the failure
      //rather than replacing a readable screen with an error page
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            Utils.getErrorMessageFromErrorCode(context, state.refreshError!),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    //the list is still holding the copy it handed over; give it the one just
    //read so backing out does not step back in time
    context.read<ChildFeeDetailsCubit>().updateFee(state.fee);

    _dropChoicesTheFreshFeeHasClosed(state.fee);
  }

  /// Drops payment choices the refreshed fee has made impossible: an optional
  /// fee settled since it was ticked, an advance now above what is left to pay.
  void _dropChoicesTheFreshFeeHasClosed(ChildFeeDetails fee) {
    final payableOptionalFeeIds = (fee.optionalFees ?? [])
        .where((optionalFee) =>
            !(optionalFee.isPaid ?? false) &&
            !fee.isOptionalFeePending(optionalFeeId: optionalFee.id ?? 0))
        .map((optionalFee) => optionalFee.id)
        .toSet();
    final keptSelections =
        _toPayOptionalFeeIds.where(payableOptionalFeeIds.contains).toList();

    final maximumAdvance = fee.maximumAdvanceInstallmentAmount();
    final clampedAdvance =
        _advanceAmount > maximumAdvance ? maximumAdvance : _advanceAmount;

    if (keptSelections.length == _toPayOptionalFeeIds.length &&
        clampedAdvance == _advanceAmount) {
      return;
    }

    setState(() {
      _toPayOptionalFeeIds = keptSelections;
      _advanceAmount = clampedAdvance;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize PaymentGatewayService with required dependencies from context
    if (_paymentGatewayService == null) {
      _paymentGatewayService = PaymentGatewayService(
        context: context,
        razorpay: _razorpay,
        onPaymentComplete: () {}, // Will be set during payment
        paymentDataProvider: context.read<PrePaymentTasksCubit>(),
        schoolConfigCubit: context.read<SchoolConfigurationCubit>(),
        authCubit: context.read<AuthCubit>(),
      );
    }
  }

  @override
  void dispose() {
    _paymentGatewayService?.dispose();
    super.dispose();
  }

  String getCurrencySymbol() {
    return context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .schoolSettings
            .currencySymbol ??
        '';
  }

  TextStyle getPaidOnTextStyle() {
    return TextStyle(
        fontSize: 12.0,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.75));
  }

  /// Section heading (e.g. "Fee Breakdown") — Poppins Medium 14, #212121.
  TextStyle _sectionTitleStyle() => TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Theme.of(context).colorScheme.secondary,
      );

  /// Breakdown line label — Poppins Regular 12, #494949.
  TextStyle _breakdownLabelStyle() => TextStyle(
        fontSize: 12.0,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurface,
      );

  /// Breakdown line value — Poppins Regular 12, #212121.
  TextStyle _breakdownValueStyle() => TextStyle(
        fontSize: 12.0,
        color: Theme.of(context).colorScheme.secondary,
      );

  /// Total row — Poppins Medium 14, #212121.
  TextStyle _totalRowStyle() => TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Theme.of(context).colorScheme.secondary,
      );

  /// Outlined card container (1.5px #DFDFDF border, 16 radius, 16 padding).
  Widget _borderedCard({required Widget child}) => FeeSectionCard(child: child);

  /// 1px divider line used inside cards.
  Widget _cardLine() => const FeeCardDivider();

  Widget _sectionTitle(String title) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(title, style: _sectionTitleStyle()),
      );

  /// A single label/value line inside a breakdown card.
  Widget _breakdownRow({
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal ? _totalRowStyle() : _breakdownLabelStyle(),
          ),
        ),
        const SizedBox(width: 24.0),
        Text(
          value,
          style: isTotal
              ? _totalRowStyle()
              : (valueColor != null
                  ? _breakdownValueStyle().copyWith(color: valueColor)
                  : _breakdownValueStyle()),
        ),
      ],
    );
  }

  Widget _buildPayInInstallmentsCard() {
    return _borderedCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              Utils.getTranslatedLabel(payInInstallmentsKey),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          SizedBox(
            height: 24.0,
            child: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: _enablePayInInstallments,
                onChanged: (value) {
                  _enablePayInInstallments = value;
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether to offer the choice between paying in full and in installments.
  ///
  /// Only while the fee is still open to both. A payment already filed — even
  /// one the school has yet to confirm — has made the choice, and offering it
  /// again would invite a second payment down the other route.
  bool showPayInInstallmentsContainer() {
    //if intallment allowed by school
    if (_fee.includeFeeInstallments ?? false) {
      return _fee.canStillChooseHowToPay();
    }
    return false;
  }

  //
  void onTapSelectOptionalFee({required int optionalFeeId}) {
    //belt and braces: the row offers no box to tick for one under review, and
    //this makes sure no other path can select it either
    if (_fee.isOptionalFeePending(
      optionalFeeId: optionalFeeId,
    )) {
      return;
    }

    if (_toPayOptionalFeeIds.contains(optionalFeeId)) {
      _toPayOptionalFeeIds.removeWhere((element) => element == optionalFeeId);
    } else {
      _toPayOptionalFeeIds.add(optionalFeeId);
    }
    setState(() {});
  }

  void prePaymentTasksListener(
      BuildContext context, PrePaymentTasksState state) {
    _paymentGatewayService?.handlePrePaymentTasksListener(
      state: state,
      paymentMethodGetter: (state) =>
          (state as PrePaymentTasksSuccess).paymentMethod.paymentMethod ?? "",
      apiKeyGetter: (state) =>
          (state as PrePaymentTasksSuccess).paymentMethod.apiKey ?? "",
      errorMessageGetter: (state) =>
          (state as PrePaymentTasksFailure).errorMessage,
      isFailureState: (state) => state is PrePaymentTasksFailure,
      isSuccessState: (state) => state is PrePaymentTasksSuccess,
    );
  }

  ///[Opens the manual payment screen with everything describing this payment]
  void _openManualPaymentScreen({
    required double payableAmount,
    double? advanceAmount,
    List<int>? installmentIds,
  }) {
    Get.toNamed(
      Routes.manualFeePayment,
      arguments: ManualFeePaymentArguments(
        childId: widget.child.id ?? 0,
        feeId: _fee.id ?? 0,
        compulsoryFee: _currentlySelectedTabKey == compulsoryTitleKey,
        optionalFeeIds: List<int>.from(_toPayOptionalFeeIds),
        installmentIds: List<int>.from(installmentIds ?? const []),
        advanceAmount: advanceAmount ?? 0.0,
        payableAmount: payableAmount,
      ),
    );
  }

  /// Decides which of the two payment flows the parent lands in.
  ///
  /// The choice is only worth asking about when the school has both routes
  /// open — with a single one enabled this goes straight there, so nobody is
  /// shown a sheet with one option.
  void _startPaymentFlow({
    required double payableAmount,
    double? advanceAmount,
    List<int>? installmentIds,
  }) {
    final schoolConfiguration =
        context.read<SchoolConfigurationCubit>().getSchoolConfiguration();

    if (!schoolConfiguration.isManualFeePaymentEnable()) {
      ///[Online only — unchanged behaviour]
      context
          .read<LatestPaymentTransactionCubit>()
          .fetchLatestPaymentTransactions();
      return;
    }

    if (!schoolConfiguration.isOnlineFeePaymentEnable()) {
      ///[Manual only — there is no gateway to fall back on]
      _openManualPaymentScreen(
        payableAmount: payableAmount,
        advanceAmount: advanceAmount,
        installmentIds: installmentIds,
      );
      return;
    }

    Utils.showBottomSheet(
      child: const SelectFeePaymentMethodBottomsheet(),
      context: context,
    ).then((selectedMethod) {
      if (selectedMethod == null) {
        return;
      }

      if (selectedMethod == FeePaymentMethod.manual) {
        _openManualPaymentScreen(
          payableAmount: payableAmount,
          advanceAmount: advanceAmount,
          installmentIds: installmentIds,
        );
        return;
      }

      ///[The pending transaction check only guards the gateway flow]
      context
          .read<LatestPaymentTransactionCubit>()
          .fetchLatestPaymentTransactions();
    });
  }

  //
  void startPrePaymentProcess(
      {double? advanceAmount, List<int>? installmentIds}) {
    ///[Will check for multiple enabled payment gateways]
    ///[Manual payment ships in the same list but is not a gateway, so it is
    ///excluded here — it has no api key and no order to create]
    final enabledPaymentGateways = context
        .read<SchoolConfigurationCubit>()
        .getSchoolConfiguration()
        .onlinePaymentGateways;

    ///[If there is only one enabled payment gateway then start the prepayment process]
    if (enabledPaymentGateways.length == 1) {
      context.read<PrePaymentTasksCubit>().performPrePaymentTasks(
          advanceAmount: advanceAmount,
          installmentIds: installmentIds,
          optionalFeeIds: _toPayOptionalFeeIds,
          compulsoryFee: _currentlySelectedTabKey == compulsoryTitleKey,
          paymentMethod: enabledPaymentGateways.first,
          childId: widget.child.id ?? 0,
          feeId: _fee.id ?? 0);
    } else {
      ///[If multiple payment gateway enabled by school then user need to select the payment gateway]
      Utils.showBottomSheet(
              child: SelectPaymentMethodBottomsheet(
                  paymentGeteways: enabledPaymentGateways),
              context: context)
          .then((selectedPaymentMethod) {
        if (selectedPaymentMethod != null) {
          ///[Start the prepayment process with selected payment gateway]
          context.read<PrePaymentTasksCubit>().performPrePaymentTasks(
              advanceAmount: advanceAmount,
              installmentIds: installmentIds,
              optionalFeeIds: _toPayOptionalFeeIds,
              compulsoryFee: _currentlySelectedTabKey == compulsoryTitleKey,
              paymentMethod: selectedPaymentMethod as PaymentGeteway,
              childId: widget.child.id ?? 0,
              feeId: _fee.id ?? 0);
        }
      });
    }
  }

  ///[Listener of latest payment transaction cubit]
  void latestPaymentTransactionListener(
      {required LatestPaymentTransactionState state,
      double? advanceAmount,
      List<int>? installmentIds}) {
    if (state is LatestPaymentTransactionFetchSuccess) {
      ///[If there is any pending transaciton by this user in recent time then show the warning]
      if (context
          .read<LatestPaymentTransactionCubit>()
          .doesUserHaveLatestPendingTransactions()) {
        ///[Show warning]
        Get.dialog<bool>(PendingTransactionWarningDialog()).then((value) {
          if (value != null && value) {
            startPrePaymentProcess(
                advanceAmount: advanceAmount, installmentIds: installmentIds);
          }
        });
      } else {
        startPrePaymentProcess(
            advanceAmount: advanceAmount, installmentIds: installmentIds);
      }
    } else if (state is LatestPaymentTransactionFetchFailure) {
      Utils.showCustomSnackBar(
          context: context,
          errorMessage:
              Utils.getErrorMessageFromErrorCode(context, state.errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error);
    }
  }

  ///[Opens the fee receipt for printing or saving]
  void _printFeeReceipt() {
    Get.dialog(
      BlocProvider(
        create: (context) => DownloadFeeReceiptCubit(FeeRepository()),
        child: DownloadReceiptDialog(
          child: widget.child,
          childFeeDetails: _fee,
        ),
      ),
    );
  }

  /// The fee's actions, gathered behind one menu in the app bar.
  ///
  /// Printing is only offered once something has been paid against the fee —
  /// there is no receipt before that — while the payment history is always
  /// worth reaching, including to find out why a payment was refused.
  void _openFeeDetailsMenu() {
    final hasSomethingToPrint = (_fee.paidFees ?? []).isNotEmpty;

    Utils.showBottomSheet(
      context: context,
      child: FeeDetailsMenuBottomsheet(
        //each action closes the menu first, so it is not left covering the
        //screen the parent lands on
        onPrint: hasSomethingToPrint
            ? () {
                Get.back();
                _printFeeReceipt();
              }
            : null,
        onViewTransactionHistory: () {
          Get.back();
          _openFeeTransactions();
        },
      ),
    );
  }

  Widget _buildAppBarMenuButton() {
    return GestureDetector(
      onTap: _openFeeDetailsMenu,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.transparent)),
        child: Icon(
          Icons.more_vert,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomBackButton(
                onTap: () {
                  if (context.read<PrePaymentTasksCubit>().state
                      is PrePaymentTasksInProgress) {
                    return;
                  }
                  if (context.read<LatestPaymentTransactionCubit>().state
                      is LatestPaymentTransactionFetchInProgress) {
                    return;
                  }
                  Get.back();
                },
              ),
              Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                        end: Utils.screenContentHorizontalPadding),
                    child: _buildAppBarMenuButton(),
                  )),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    Utils.getTranslatedLabel(feeDetailsKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                curve: Utils.tabBackgroundContainerAnimationCurve,
                duration: Utils.tabBackgroundContainerAnimationDuration,
                alignment: _currentlySelectedTabKey == compulsoryTitleKey
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child:
                    TabBarBackgroundContainer(boxConstraints: boxConstraints),
              ),
              CustomTabBarContainer(
                boxConstraints: boxConstraints,
                alignment: AlignmentDirectional.centerStart,
                isSelected: _currentlySelectedTabKey == compulsoryTitleKey,
                onTap: () {
                  if (context.read<PrePaymentTasksCubit>().state
                      is PrePaymentTasksInProgress) {
                    return;
                  }
                  if (context.read<LatestPaymentTransactionCubit>().state
                      is LatestPaymentTransactionFetchInProgress) {
                    return;
                  }
                  setState(() {
                    _currentlySelectedTabKey = compulsoryTitleKey;
                  });
                },
                titleKey: compulsoryTitleKey,
              ),
              CustomTabBarContainer(
                boxConstraints: boxConstraints,
                alignment: AlignmentDirectional.centerEnd,
                isSelected: _currentlySelectedTabKey == optionalTitleKey,
                onTap: () {
                  if (context.read<PrePaymentTasksCubit>().state
                      is PrePaymentTasksInProgress) {
                    return;
                  }
                  if (context.read<LatestPaymentTransactionCubit>().state
                      is LatestPaymentTransactionFetchInProgress) {
                    return;
                  }
                  setState(() {
                    _currentlySelectedTabKey = optionalTitleKey;
                  });
                },
                titleKey: optionalTitleKey,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentInfoBackgroundContainer({required Widget child}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
                blurRadius: 2.0,
                color: Colors.black.withValues(alpha: 0.08),
                spreadRadius: 0.0,
                offset: const Offset(0, -2))
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          )),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  /// Clamps the chosen advance [value] to the allowed range and updates state so
  /// the Payable Amount recalculates immediately.
  ///
  /// The value arrives through the bottom sheet's onAmountSelected callback,
  /// which is the reliable channel — the Get.back result via `.then` can
  /// silently fail and leave the amount unapplied.
  void _applyAdvanceAmount(double value, double maximumAdvanceAmount) {
    var parsed = value;

    // Guard against NaN / negative / above-maximum values. The clamp also
    // applies when the maximum is 0 — that means "no advance allowed", not
    // "no limit".
    if (parsed.isNaN || parsed < 0.0) {
      parsed = 0.0;
    }
    if (parsed > maximumAdvanceAmount) {
      parsed = maximumAdvanceAmount;
    }

    if (!mounted) {
      return;
    }
    if (parsed != _advanceAmount) {
      setState(() {
        _advanceAmount = parsed;
      });
    }
  }

  Widget _buildAdvanceAmountContainer(double maximumAdvanceAmount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            Utils.getTranslatedLabel(advanceAmountKey),
            style: TextStyle(
              fontSize: 12.0,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          "${getCurrencySymbol()}${_advanceAmount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        Material(
          child: Builder(builder: (context) {
            return GestureDetector(
              onTap: () {
                Utils.showBottomSheet(
                  child: AdvanceInstallmentAmountBottomsheet(
                    advanceInstallmentAmount: _advanceAmount,
                    maximumAmountLimit: maximumAdvanceAmount,
                    // Reliable channel: the sheet delivers the chosen value the
                    // moment the user confirms/clears. The Get.back result via
                    // `.then` can silently fail, so it is not relied upon.
                    onAmountSelected: (amount) =>
                        _applyAdvanceAmount(amount, maximumAdvanceAmount),
                  ),
                  context: context,
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent)),
                child: Icon(
                  Icons.edit,
                  size: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        )
      ],
    );
  }

  ///[If compulsory fee is selected then show payment info]
  Widget _buildCompulsoryInstallmentPaymentInfoContainer() {
    // Computed once here and reused (visibility gate + advance editor) instead
    // of being recomputed for each read.
    final maximumAdvanceAmount = _fee.maximumAdvanceInstallmentAmount();

    // Get all outstanding installments (ones that are due but not paid)
    final outstandingInstallments = _fee.dueInstallments();

    // Get current installment
    final currentInstallment = _fee.currentInstallment();

    // Get next installment if current is already paid
    final nextInstallment = (currentInstallment.isPaid ?? false)
        ? _fee.nextUnpaidInstallment()
        : currentInstallment;

    // Whether the next installment is part of this payment (exists, not paid
    // yet, and not already counted among the outstanding/overdue installments).
    final isNextInstallmentInThisPayment = nextInstallment.id != null &&
        !(nextInstallment.isPaid ?? false) &&
        !outstandingInstallments.any((inst) => inst.id == nextInstallment.id);

    // Amount payable for the next installment: remaining minus any advance
    // already paid toward it, matching the per-installment card display.
    final nextInstallmentAmount = isNextInstallmentInThisPayment
        ? _fee.installmentAmountAfterAdvance(nextInstallment)
        : 0.0;

    // Net for the next installment after its own relief (never negative) —
    // this is what actually gets charged for it.
    final nextInstallmentNetAmount = isNextInstallmentInThisPayment
        ? _fee.netRemainingOfInstallment(nextInstallment)
        : 0.0;

    // Split the outstanding installments into their base (fee) part and their
    // due charge (penalty) part, so the penalty can be shown on its own line.
    // The base part is net of advances already paid toward each installment;
    // the net part additionally deducts each installment's own relief.
    double outstandingBaseAmount = 0.0;
    double outstandingNetAmount = 0.0;
    double dueChargesAmount = 0.0;
    for (var installment in outstandingInstallments) {
      outstandingBaseAmount += _fee.installmentAmountAfterAdvance(installment);
      outstandingNetAmount += _fee.netRemainingOfInstallment(installment);
      dueChargesAmount += (installment.dueChargeAmount ?? 0.0);
    }

    // Include the due charge of the next/current installment too, when it is
    // overdue and part of this payment (i.e. not one of the outstanding ones).
    // Gated on membership in the payment — not on the amount — because an
    // advance can bring the payable amount to zero while the penalty is still owed.
    if (isNextInstallmentInThisPayment &&
        nextInstallment.isInstallmentOverdue()) {
      dueChargesAmount += (nextInstallment.dueChargeAmount ?? 0.0);
    }

    // Collect installment IDs for payment
    List<int> installmentIds = [];

    // Add next installment ID only if it's part of this payment
    if (isNextInstallmentInThisPayment) {
      installmentIds.add(nextInstallment.id!);
    }

    // Add all outstanding installment IDs
    for (var installment in outstandingInstallments) {
      if (installment.id != null) {
        installmentIds.add(installment.id!);
      }
    }

    // Relief effectively applied to this payment, derived per installment as
    // (base - net). This clamps each installment's relief to its own base —
    // matching the per-installment cards — so the summary rows always
    // reconcile: bases − relief + advance + due charges = payable.
    final reliefAmount = (nextInstallmentAmount - nextInstallmentNetAmount) +
        (outstandingBaseAmount - outstandingNetAmount);
    final hasRelief = reliefAmount > 0.0;
    final hasDueCharges = dueChargesAmount > 0.0;

    // Payable = net of every installment being paid now + the user-entered
    // advance + due charges. The advance is added after relief (relief can
    // never swallow it), and relief never reduces the due charge penalty,
    // mirroring the full payment flow.
    final payableAmount = nextInstallmentNetAmount +
        outstandingNetAmount +
        _advanceAmount +
        dueChargesAmount;

    return _buildPaymentInfoBackgroundContainer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show outstanding installments section if any due installments exist
        // (base fee only — the due charge is shown on its own line below).
        if (outstandingBaseAmount > 0.0) ...[
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(outstandingInstallmentKey),
            value:
                "${getCurrencySymbol()}${outstandingBaseAmount.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 12.0),
        ],
        // Show next installment section only if it's not already in outstanding
        if (nextInstallmentAmount > 0.0) ...[
          _buildPaymentSummaryRow(
            label: nextInstallment.name ?? '',
            value:
                "${getCurrencySymbol()}${nextInstallmentAmount.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 12.0),
        ],
        // Show the advance amount section only when an advance is actually
        // possible (or one is already entered and may need clearing) —
        // otherwise the editor is a dead end that can only reject every input.
        if (maximumAdvanceAmount > 0.0 || _advanceAmount > 0.0) ...[
          _buildAdvanceAmountContainer(maximumAdvanceAmount),
          const SizedBox(height: 12.0),
        ],
        // Due charges (penalty) for the selected installments
        if (hasDueCharges) ...[
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(dueChargesKey),
            value:
                "+${getCurrencySymbol()}${dueChargesAmount.toStringAsFixed(2)}",
            valueColor: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12.0),
        ],
        // Relief / discount for the selected installments
        if (hasRelief) ...[
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(reliefAmountKey),
            value: "-${getCurrencySymbol()}${reliefAmount.toStringAsFixed(2)}",
            valueColor: Theme.of(context).colorScheme.onSecondary,
          ),
          const SizedBox(height: 12.0),
        ],
        _cardLine(),
        const SizedBox(height: 12.0),
        // Payable total after relief
        _buildPaymentSummaryRow(
          label: Utils.getTranslatedLabel(payableAmountKey),
          value: "${getCurrencySymbol()}${payableAmount.toStringAsFixed(2)}",
          isPayable: true,
        ),
        nextInstallment.id == null
            ? Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  "${Utils.getTranslatedLabel(nextInstallmentPaymentStartsFromKey)} ${currentInstallment.dueDate}",
                  style: getPaidOnTextStyle(),
                ),
              )
            : const SizedBox(),
        const SizedBox(
          height: 16,
        ),
        // Only show the pay button if there are installments to pay or advance amount
        (installmentIds.isNotEmpty || _advanceAmount > 0)
            ? _buildPayNowButton(
                payableAmount: payableAmount,
                installmentIds: installmentIds,
                advanceAmount: _advanceAmount)
            : const SizedBox()
      ],
    ));
  }

  ///[A single label/value row used inside the bottom payment summary]
  ///[isPayable -> the prominent "Payable Amount" total row (Poppins Medium 16)]
  Widget _buildPaymentSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isPayable = false,
  }) {
    final labelStyle = isPayable
        ? TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
            color: Theme.of(context).colorScheme.secondary,
          )
        : TextStyle(
            fontSize: 12.0,
            letterSpacing: 0.4,
            color: Theme.of(context).colorScheme.onSurface,
          );
    final valueStyle = isPayable
        ? TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
            color: Theme.of(context).colorScheme.secondary,
          )
        : TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: valueColor ?? Theme.of(context).colorScheme.secondary,
          );
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 8.0),
        Text(value, style: valueStyle),
      ],
    );
  }

  ///[If compulsory fee is selected then show payment info]
  Widget _buildCompulsoryFullPaidPaymentInfoContainer() {
    final feeAmount = _fee.totalCompulsoryFees ?? 0.0;
    final isOverDue = _fee.isFeeOverDue();
    final dueAmount = isOverDue ? (_fee.dueChargesAmount ?? 0.0) : 0.0;

    final reliefAmount = _fee.totalCompulsoryDiscountAmount();
    final hasRelief = _fee.hasCompulsoryDiscount() && reliefAmount > 0.0;
    final hasDueCharges = isOverDue && dueAmount > 0.0;

    // Payable = fee - relief + due charges (relief never makes it negative).
    final payableAmount =
        ((feeAmount - reliefAmount) > 0.0 ? (feeAmount - reliefAmount) : 0.0) +
            dueAmount;

    return _buildPaymentInfoBackgroundContainer(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaymentSummaryRow(
          label: Utils.getTranslatedLabel(totalFeeAmountKey),
          value: "${getCurrencySymbol()}${feeAmount.toStringAsFixed(2)}",
        ),
        // Due charges (penalty) shown before relief, matching the installment flow.
        if (hasDueCharges) ...[
          const SizedBox(height: 12.0),
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(dueChargesKey),
            value: "+${getCurrencySymbol()}${dueAmount.toStringAsFixed(2)}",
            valueColor: Theme.of(context).colorScheme.error,
          ),
        ],
        if (hasRelief) ...[
          const SizedBox(height: 12.0),
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(reliefAmountKey),
            value: "-${getCurrencySymbol()}${reliefAmount.toStringAsFixed(2)}",
            valueColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ],
        const SizedBox(height: 12.0),
        _cardLine(),
        const SizedBox(height: 12.0),
        _buildPaymentSummaryRow(
          label: Utils.getTranslatedLabel(payableAmountKey),
          value: "${getCurrencySymbol()}${payableAmount.toStringAsFixed(2)}",
          isPayable: true,
        ),
        const SizedBox(height: 16.0),
        _buildPayNowButton(payableAmount: payableAmount)
      ],
    ));
  }

  Widget _buildOptionalBottmsheetPaymentInfoContainer() {
    if (!_fee.hasOptionalFees()) {
      return const SizedBox();
    }

    if (_fee.hasAnyUnpaidOptionlFee()) {
      double totalAmount = 0.0;
      double reliefAmount = 0.0;
      for (var optionalFee
          in (_fee.optionalFees ?? ([] as List<ClassFeeType>))) {
        if (_toPayOptionalFeeIds.contains(optionalFee.id)) {
          totalAmount = (optionalFee.amount ?? 0.0) + totalAmount;
          reliefAmount = (optionalFee.discountAmount ?? 0.0) + reliefAmount;
        }
      }

      final hasRelief = reliefAmount > 0.0;
      final payableAmount = (totalAmount - reliefAmount) > 0.0
          ? (totalAmount - reliefAmount)
          : 0.0;

      //
      return _buildPaymentInfoBackgroundContainer(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(totalFeeAmountKey),
            value: "${getCurrencySymbol()}${totalAmount.toStringAsFixed(2)}",
          ),
          if (hasRelief) ...[
            const SizedBox(height: 12.0),
            _buildPaymentSummaryRow(
              label: Utils.getTranslatedLabel(reliefAmountKey),
              value:
                  "-${getCurrencySymbol()}${reliefAmount.toStringAsFixed(2)}",
              valueColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ],
          const SizedBox(height: 12.0),
          _cardLine(),
          const SizedBox(height: 12.0),
          _buildPaymentSummaryRow(
            label: Utils.getTranslatedLabel(payableAmountKey),
            value: "${getCurrencySymbol()}${payableAmount.toStringAsFixed(2)}",
            isPayable: true,
          ),
          const SizedBox(height: 16.0),
          _buildPayNowButton(payableAmount: payableAmount)
        ],
      ));
    }

    return const SizedBox();
  }

  Widget _buildCompulsoryBottomPaymentInfoContainer() {
    if (_fee.isCompulsoryFeeFullyPaid()) {
      return const SizedBox();
    }

    if (_isInInstallmentMode) {
      return _buildCompulsoryInstallmentPaymentInfoContainer();
    }

    return _buildCompulsoryFullPaidPaymentInfoContainer();
  }

  /// Banner shown when the last payment the school handled came back refused —
  /// a receipt turned down, a cheque bounced.
  Widget _buildRejectedManualPaymentBanner() {
    //the refusal belongs to the side of the fee it was filed against, so it
    //shows on that tab only
    if (!_fee.hasRejectedPayment(compulsory: _isCompulsoryTabSelected)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RejectedPaymentBanner(onTap: _openRejectedPaymentSheet),
    );
  }

  /// Opens the refusal in a sheet: the school's reason, and the way on to the
  /// payment history.
  void _openRejectedPaymentSheet() {
    Utils.showBottomSheet(
      context: context,
      child: RejectedPaymentBottomsheet(
        reason:
            _fee.rejectedPaymentReason(compulsory: _isCompulsoryTabSelected),
        //the sheet closes first, so returning from the history lands back on
        //the fee rather than behind a sheet still covering it
        onViewTransaction: () {
          Get.back();
          _openFeeTransactions();
        },
      ),
    );
  }

  ///[This fee's payment history, where a rejection and its reason are recorded]
  void _openFeeTransactions() {
    Get.toNamed(
      Routes.feeTransactions,
      arguments: {
        "childId": widget.child.id ?? 0,
        "feesId": _fee.id,
      },
    );
  }

  /// Replaces the pay section while a manual receipt is awaiting the school.
  ///
  /// Paying again here would file a second receipt for the same money, so the
  /// action offered is to go and check on the one already sent rather than to
  /// pay. Only on the tab the receipt was filed against: compulsory and
  /// optional fees are paid separately, so a receipt sent for one leaves the
  /// other still payable.
  Widget _buildPendingManualPaymentContainer() {
    return _buildPaymentInfoBackgroundContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: warningContainerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              Utils.getTranslatedLabel(
                Utils.pendingPaymentNoteLabelKey(
                  _fee.pendingPaymentMode(compulsory: _isCompulsoryTabSelected),
                ),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                height: 16 / 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          CustomRoundedButton(
            height: 48,
            radius: 8.0,
            widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                MediaQuery.of(context).size.width,
            textSize: 16.0,
            fontWeight: FontWeight.w500,
            backgroundColor: Theme.of(context).colorScheme.primary,
            buttonTitle: Utils.getTranslatedLabel(viewTransactionKey),
            showBorder: false,
            //scoped to this fee, so the parent lands on the receipt they just
            //sent rather than the child's entire payment history
            onTap: _openFeeTransactions,
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton(
      {required double payableAmount,
      double? advanceAmount,
      List<int>? installmentIds}) {
    return BlocConsumer<LatestPaymentTransactionCubit,
        LatestPaymentTransactionState>(
      listener: (context, state) {
        latestPaymentTransactionListener(
            state: state,
            advanceAmount: advanceAmount,
            installmentIds: installmentIds);
      },
      builder: (context, state) {
        return BlocConsumer<PrePaymentTasksCubit, PrePaymentTasksState>(
          listener: prePaymentTasksListener,
          builder: (context, paymentTaskState) {
            return PopScope(
              canPop: (state is! LatestPaymentTransactionFetchInProgress) &&
                  (paymentTaskState is! PrePaymentTasksInProgress),
              child: CustomRoundedButton(
                height: 48,
                radius: 8.0,
                // Full width within the bottom sheet's 16px horizontal padding.
                widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                    MediaQuery.of(context).size.width,
                textSize: 16.0,
                fontWeight: FontWeight.w500,
                backgroundColor: Theme.of(context).colorScheme.primary,
                buttonTitle: Utils.getTranslatedLabel(payNowKey),
                showBorder: false,
                child: (paymentTaskState is PrePaymentTasksInProgress) ||
                        (state is LatestPaymentTransactionFetchInProgress)
                    ? CustomCircularProgressIndicator(
                        widthAndHeight: 20,
                        strokeWidth: 2,
                      )
                    : null,
                onTap: () {
                  if (state is LatestPaymentTransactionFetchInProgress) {
                    return;
                  }
                  if (paymentTaskState is PrePaymentTasksInProgress) {
                    return;
                  }

                  if (_currentlySelectedTabKey == optionalTitleKey) {
                    ///
                    if (_toPayOptionalFeeIds.isEmpty) {
                      Utils.showCustomSnackBar(
                          context: context,
                          errorMessage: Utils.getTranslatedLabel(
                              pleaseSelectAtLeastOneOptionalFeeKey),
                          backgroundColor: Theme.of(context).colorScheme.error);
                      return;
                    }

                    ///
                  } else {
                    // If it's compulsory fees payment
                    if ((_fee.currentInstallment().isPaid ?? false)) {
                      // If current installment is paid, check if there's a next unpaid installment
                      final nextInstallment = _fee.nextUnpaidInstallment();

                      // If there's no next installment and advance amount is zero, show error
                      if (nextInstallment.id == null && _advanceAmount <= 0.0) {
                        Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: Utils.getTranslatedLabel(
                                advanceAmountCanNotBeZeroKey),
                            backgroundColor:
                                Theme.of(context).colorScheme.error);
                        return;
                      }
                    }
                  }

                  _startPaymentFlow(
                    payableAmount: payableAmount,
                    advanceAmount: advanceAmount,
                    installmentIds: installmentIds,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  ///[A single selectable optional fee row inside the breakdown card]
  Widget _buildOptionalFeeRow(ClassFeeType optionalFee) {
    ///[A manual-payment-only school still needs to pick which fees to pay]
    final isPaymentEnabled = context
        .read<SchoolConfigurationCubit>()
        .getSchoolConfiguration()
        .isAnyFeePaymentEnable();
    final isFeeSelectedToPay =
        _toPayOptionalFeeIds.contains(optionalFee.id ?? 0);
    final isPaid = optionalFee.isPaid ?? false;
    //this fee's own payment, not the tab's: paying for Sports leaves GYM
    //exactly as payable as it was
    final isUnderReview = !isPaid &&
        _fee.isOptionalFeePending(optionalFeeId: optionalFee.id ?? 0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isPaymentEnabled) ...[
          isPaid
              ? Icon(Icons.verified,
                  size: 20.0, color: Theme.of(context).colorScheme.onSecondary)
              : isUnderReview
                  //no box to tick: the money for this one is already with the
                  //school, and ticking it again would send it twice
                  ? Icon(Icons.hourglass_top_rounded,
                      size: 20.0, color: Theme.of(context).colorScheme.primary)
                  : GestureDetector(
                      onTap: () {
                        onTapSelectOptionalFee(
                            optionalFeeId: optionalFee.id ?? 0);
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.center,
                        child: isFeeSelectedToPay
                            ? Icon(Icons.check,
                                size: 15.0,
                                color: Theme.of(context).colorScheme.primary)
                            : const SizedBox(),
                      ),
                    ),
          const SizedBox(width: 10.0),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                optionalFee.feesType?.name ?? optionalFee.feesTypeName ?? "",
                style: _breakdownLabelStyle(),
              ),
              if (isPaid)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    "${Utils.getTranslatedLabel(paidOnKey)} ${_formatOptionalPaidDate(_fee.optionalPaidDate(optionalFeeId: optionalFee.id ?? 0))}",
                    style: getPaidOnTextStyle(),
                  ),
                ),
              //said in the same place, and the same way, as "Paid on ..."
              if (isUnderReview)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    Utils.getTranslatedLabel(underReviewKey),
                    style: getPaidOnTextStyle().copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24.0),
        Text(
          "${getCurrencySymbol()}${(optionalFee.amount ?? 0).toStringAsFixed(2)}",
          style: _breakdownValueStyle(),
        ),
      ],
    );
  }

  Widget _buildOptionalFeesContainer() {
    final optionalFees = _fee.optionalFees ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (optionalFees.isNotEmpty) ...[
          _sectionTitle(Utils.getTranslatedLabel(feeBreakdownKey)),
          const SizedBox(height: 8.0),
          _borderedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < optionalFees.length; i++) ...[
                  if (i != 0) ...[
                    const SizedBox(height: 12.0),
                    _cardLine(),
                    const SizedBox(height: 12.0),
                  ],
                  _buildOptionalFeeRow(optionalFees[i]),
                ],
              ],
            ),
          ),
        ],

        // ---- Fee Relief (discount) for optional scope ----
        if (_fee.hasOptionalDiscount()) ...[
          const SizedBox(height: 16.0),
          FeeReliefContainer(
            childFeeDetails: _fee,
            compulsory: false,
          ),
        ],

        const SizedBox(height: 50.0),
      ],
    );
  }

  /// Fee Breakdown card: what the fee is made of, what it comes to, the late
  /// fees on top of it, and what has actually been paid.
  ///
  /// The late fee row is deliberately not conditional on the fee being overdue
  /// *right now* — a collected late fee is still part of what the fee cost, and
  /// dropping it once paid is what left the card 500 short of the real total.
  Widget _buildCompulsoryBreakdownCard() {
    final feeDetails = _fee;
    final inInstallmentMode = _isInInstallmentMode;

    final fees = feeDetails.compulsoryFees ?? [];
    final children = <Widget>[];

    void addSeparator() {
      children.add(const SizedBox(height: 12.0));
      children.add(_cardLine());
      children.add(const SizedBox(height: 12.0));
    }

    for (var fee in fees) {
      children.add(_breakdownRow(
        label: fee.feesType?.name ?? fee.feesTypeName ?? "",
        value: "${getCurrencySymbol()}${(fee.amount ?? 0).toStringAsFixed(2)}",
      ));
      addSeparator();
    }

    children.add(_breakdownRow(
      label: Utils.getTranslatedLabel(totalFeeKey),
      value:
          "${getCurrencySymbol()}${(feeDetails.totalCompulsoryFees ?? 0).toStringAsFixed(2)}",
      isTotal: true,
    ));

    // Late fees, whether still owed or collected with an earlier installment.
    final dueCharges =
        feeDetails.totalDueChargesAmount(inInstallmentMode: inInstallmentMode);
    if (dueCharges > 0.0) {
      addSeparator();
      children.add(_breakdownRow(
        //the fee level percentage describes only the single charge on the whole
        //fee; in installments each carries its own rate, stated on its card
        label: inInstallmentMode
            ? Utils.getTranslatedLabel(dueChargesKey)
            : "${Utils.getTranslatedLabel(dueKey)} (${feeDetails.dueChargesInPercentage}%)",
        value: "+${getCurrencySymbol()}${dueCharges.toStringAsFixed(2)}",
        valueColor: Theme.of(context).colorScheme.error,
      ));
    }

    // What the parent has actually handed over, fee and late fees together.
    if (feeDetails.hasPaidAnyAmount()) {
      addSeparator();
      children.add(_breakdownRow(
        label: Utils.getTranslatedLabel(totalPaidKey),
        value:
            "${getCurrencySymbol()}${feeDetails.totalAmountPaid().toStringAsFixed(2)}",
        isTotal: true,
      ));
    }

    // Paid-on line for a fully paid (non installment) fee.
    if (feeDetails.hasUserPaidFullFeeWithoutInstallment()) {
      addSeparator();
      children.add(_breakdownRow(
        label: Utils.getTranslatedLabel(paidOnKey),
        value: _formatOptionalPaidDate(feeDetails.fullCompulsoryFeePaidDate()),
      ));
    }

    return _borderedCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }

  ///[Installments card with the list of installments and remaining amount]
  /// Installments card: every installment, then where the fee stands overall.
  ///
  /// The late fees and the paid total are stated here rather than on the Fee
  /// Breakdown card, which an installment fee does not show — otherwise the
  /// only figure the parent gets is what is left, and never what they paid.
  Widget _buildInstallmentsCard() {
    final children = <Widget>[Installments(childFeeDetails: _fee)];

    void addRow({
      required String label,
      required String value,
      Color? valueColor,
    }) {
      children.add(_cardLine());
      children.add(const SizedBox(height: 12.0));
      children.add(Row(
        children: [
          Expanded(child: Text(label, style: _totalRowStyle())),
          const SizedBox(width: 24.0),
          Text(
            value,
            style: valueColor == null
                ? _totalRowStyle()
                : _totalRowStyle().copyWith(color: valueColor),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12.0));
    }

    final dueCharges = _fee.totalDueChargesAmount(inInstallmentMode: true);
    if (dueCharges > 0.0) {
      addRow(
        label: Utils.getTranslatedLabel(dueChargesKey),
        value: "+${getCurrencySymbol()}${dueCharges.toStringAsFixed(2)}",
        valueColor: Theme.of(context).colorScheme.error,
      );
    }

    if (_fee.hasPaidAnyAmount()) {
      addRow(
        label: Utils.getTranslatedLabel(totalPaidKey),
        value:
            "${getCurrencySymbol()}${_fee.totalAmountPaid().toStringAsFixed(2)}",
      );
    }

    addRow(
      label: Utils.getTranslatedLabel(remainingAmountKey),
      value:
          "${getCurrencySymbol()}${_fee.remainingInstallmentAmount().toStringAsFixed(2)}",
      valueColor: Theme.of(context).colorScheme.primary,
    );

    //the last row carries the card's own bottom padding
    children.removeLast();

    return _borderedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCompulsoryFeesContainer() {
    final inInstallmentMode = _isInInstallmentMode;
    final sections = <Widget>[];

    void addSection(Widget section) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 16.0));
      }
      sections.add(section);
    }

    // ---- Fee Breakdown ----
    // The whole fee stated at once, which is the full payment route. In
    // installments the fee is told through the installments themselves — each
    // with its own amount, due date and late fee — so the two are shown one or
    // the other, never both.
    if (!inInstallmentMode) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Utils.getTranslatedLabel(feeBreakdownKey)),
          const SizedBox(height: 8.0),
          _buildCompulsoryBreakdownCard(),
        ],
      ));
    }

    // ---- Fee Relief (discount) ----
    if (_fee.hasCompulsoryDiscount()) {
      addSection(FeeReliefContainer(childFeeDetails: _fee, compulsory: true));
    }

    // ---- Pay In Installments toggle ----
    if (showPayInInstallmentsContainer()) {
      addSection(_buildPayInInstallmentsCard());
    }

    // ---- Installments list ----
    if (inInstallmentMode) {
      addSection(_buildInstallmentsCard());
    }

    sections.add(const SizedBox(height: 50.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    //everything below reads the fee through [_fee], so this is what puts a
    //freshly read one on screen
    return BlocConsumer<ChildFeeCubit, ChildFeeState>(
      listener: _childFeeListener,
      builder: (context, childFeeState) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: CustomRefreshIndicator(
                //clear of the app bar, which is stacked over the scroll view
                displacment: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
                ),
                onRefreshCallback: _refreshFee,
                child: SingleChildScrollView(
                  //a short fee would otherwise have nothing to pull on
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * (0.3),
                      left: Utils.screenContentHorizontalPadding,
                      right: Utils.screenContentHorizontalPadding,
                      top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarBiggerHeightPercentage)),
                  child: Column(
                    children: [
                      FeeInformationContainer(
                        child: widget.child,
                        childFeeDetails: _fee,
                        compulsory: _isCompulsoryTabSelected,
                      ),
                      const SizedBox(height: 16.0),
                      //sits directly under the fee summary, as designed, on the
                      //tab the refused receipt was filed against
                      _buildRejectedManualPaymentBanner(),
                      _currentlySelectedTabKey == compulsoryTitleKey
                          ? _buildCompulsoryFeesContainer()
                          : _buildOptionalFeesContainer()
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildAppBar(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              //a payment already made and awaiting the school outranks the pay
              //section: paying again would commit the same money twice, whether
              //what is outstanding is a filed receipt or a cheque still clearing
              child: _payingIsBlockedByAnUnconfirmedPayment
                  ? _buildPendingManualPaymentContainer()
                  : context
                          .read<SchoolConfigurationCubit>()
                          .getSchoolConfiguration()
                          .isAnyFeePaymentEnable()
                      ? (_currentlySelectedTabKey == compulsoryTitleKey)
                          ? _buildCompulsoryBottomPaymentInfoContainer()
                          : _buildOptionalBottmsheetPaymentInfoContainer()
                      : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
