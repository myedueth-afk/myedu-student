import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/manualFeePaymentCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/manualFeePaymentArguments.dart';
import 'package:eschool/data/models/paymentGateway.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/paymentInstructionsHtml.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/addFilesContainer.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/expandableContentContainer.dart';
import 'package:eschool/ui/widgets/labelledAmountRow.dart';
import 'package:eschool/ui/widgets/networkImageHandler.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/attachmentPicker.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Fee payment made outside the app — the parent transfers to the school's
/// account and attaches the receipt for the school to verify.
///
/// Nothing is charged here. The fee stays outstanding until the school approves
/// the receipt, which is why this lands on the same confirmation screen as a
/// gateway payment awaiting settlement rather than reporting the fee as paid.
class ManualFeePaymentScreen extends StatefulWidget {
  final ManualFeePaymentArguments arguments;

  const ManualFeePaymentScreen({Key? key, required this.arguments})
      : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<ManualFeePaymentCubit>(
      create: (_) => ManualFeePaymentCubit(FeeRepository()),
      child: ManualFeePaymentScreen(
        arguments: Get.arguments as ManualFeePaymentArguments,
      ),
    );
  }

  @override
  State<ManualFeePaymentScreen> createState() => _ManualFeePaymentScreenState();
}

class _ManualFeePaymentScreenState extends State<ManualFeePaymentScreen> {
  /// The endpoints take a single `receipt`, so picking again replaces rather
  /// than appends — attaching a second file and having it silently dropped on
  /// upload would be worse than not offering it.
  PlatformFile? _receiptFile;

  /// Optional message to the school — a transaction reference, or which
  /// installment the transfer was meant for. Sent as the endpoint's `notes`.
  final TextEditingController _noteTextEditingController =
      TextEditingController();

  @override
  void dispose() {
    _noteTextEditingController.dispose();
    super.dispose();
  }

  ///[The school's manual payment configuration, delivered with the gateways]
  PaymentGeteway? get _manualPaymentGateway => context
      .read<SchoolConfigurationCubit>()
      .getSchoolConfiguration()
      .manualPaymentGateway;

  String get _currencySymbol =>
      context
          .read<SchoolConfigurationCubit>()
          .getSchoolConfiguration()
          .schoolSettings
          .currencySymbol ??
      '';

  void _showMessage(String labelKey) {
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel(labelKey),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  Future<void> _pickFiles() async {
    try {
      //a receipt is as often a screenshot in the photo library as a file, and
      //on iOS those are two different pickers — see [AttachmentPicker]
      final files = await AttachmentPicker.pick(
        context: context,
        allowedExtensions: manualPaymentReceiptAllowedFileExtensions,
      );

      if (files.isNotEmpty) {
        setState(() => _receiptFile = files.first);
      }
    } catch (e) {
      if (!mounted) return;
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getErrorMessageFromErrorCode(context, e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Returns the label key of the first failed rule, or null when the form is
  /// ready to submit.
  ///
  /// The amount is no longer a rule — it comes from the fee screen rather than
  /// from input. It is still checked, because a payment of nothing must not
  /// reach the endpoint if the caller ever gets that wrong.
  String? _validationErrorKey() {
    if (widget.arguments.payableAmount <= 0) {
      return pleaseEnterValidAmountKey;
    }
    //the receipt is the only evidence the school has to verify against, so a
    //manual payment without one cannot be reviewed
    if (_receiptFile?.path == null) {
      return pleaseAttachPaymentReceiptKey;
    }
    return null;
  }

  void _submitPayment() {
    FocusScope.of(context).unfocus();

    if (context.read<ManualFeePaymentCubit>().state
        is ManualFeePaymentInProgress) {
      return;
    }

    final errorKey = _validationErrorKey();
    if (errorKey != null) {
      _showMessage(errorKey);
      return;
    }

    //the amount is not sent: the endpoints derive it from the fee, the
    //installments and the advance, which is what [ManualFeePaymentArguments]
    //carries
    context.read<ManualFeePaymentCubit>().submitManualFeePayment(
          arguments: widget.arguments,
          receiptFilePath: _receiptFile!.path!,
          //optional: the repository leaves the field off the request entirely
          //when it is blank
          notes: _noteTextEditingController.text.trim(),
        );
  }

  void _manualFeePaymentListener(
      BuildContext context, ManualFeePaymentState state) {
    if (state is ManualFeePaymentSuccess) {
      ///[Nothing has been paid yet — the school still has to approve the
      ///receipt — so this lands on the same "awaiting confirmation" screen the
      ///gateway flow uses, which also refreshes the fee list]
      ///
      ///The two screens behind it go with it. This form has been submitted and
      ///cannot be submitted again, and the fee details screen behind it holds
      ///the fee as it looked before the receipt was sent — returning to it
      ///would show a Pay Now button for a payment already filed. Leaving the
      ///fee list as the screen behind means Go Back, the system back gesture
      ///and the back arrow all land somewhere current.
      Get.offNamedUntil(
        Routes.confirmPayment,
        (route) => route.settings.name == Routes.childFees || route.isFirst,
      );
      return;
    }

    if (state is ManualFeePaymentFailure) {
      ///[Surfaces the backend's own message, so a receipt rejected for being
      ///too large reports the limit the panel actually has]
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            Utils.getErrorMessageFromErrorCode(context, state.errorMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  ///[Section heading above each card — Poppins Medium 14, #212121]
  Widget _buildSectionTitle(String labelKey) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        Utils.getTranslatedLabel(labelKey),
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  ///[A single label/value line inside the school instruction card]
  Widget _buildInstructionRow(
      {required String labelKey, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            Utils.getTranslatedLabel(labelKey),
            style: TextStyle(
              fontSize: 12.0,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 24.0),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Bank details card. Only the fields the school actually filled in are
  /// listed — a school collecting cash at the office may have none of them, in
  /// which case the card is dropped rather than rendered empty.
  Widget _buildSchoolInstructionCard(PaymentGeteway manualPayment) {
    final rows = <Widget>[];

    void addRow(String labelKey, String? value) {
      if ((value ?? '').trim().isEmpty) {
        return;
      }
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12.0));
        rows.add(const FeeCardDivider());
        rows.add(const SizedBox(height: 12.0));
      }
      rows.add(_buildInstructionRow(labelKey: labelKey, value: value!.trim()));
    }

    addRow(bankNameKey, manualPayment.bankName);
    addRow(accountNameKey, manualPayment.accountName);
    addRow(accountNumberKey, manualPayment.accountNo);

    //panel authored instructions may carry markup, so they are rendered rather
    //than printed
    final details = (manualPayment.details ?? '').trim();
    if (details.isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12.0));
        rows.add(const FeeCardDivider());
        rows.add(const SizedBox(height: 12.0));
      }
      rows.add(PaymentInstructionsHtml(html: details));
    }

    if (rows.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(schoolInstructionKey),
        const SizedBox(height: 8.0),
        FeeSectionCard(
          //a school may write three bank rows or three tables and a QR; folding
          //the long case keeps the amount and the receipt upload reachable
          //without scrolling past a wall of instructions first
          child: ExpandableContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  ///[The scan-to-pay image the school uploaded, when there is one]
  Widget _buildQrCard(PaymentGeteway manualPayment) {
    final imageUrl = (manualPayment.file ?? '').trim();
    if (imageUrl.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        FeeSectionCard(
          child: Center(
            child: GestureDetector(
              //the code has to be scannable, and 124px rarely is on a busy QR
              onTap: () => Utils.showImagePreview(
                context: context,
                imageUrl: imageUrl,
              ),
              child: SizedBox(
                width: 124.0,
                height: 124.0,
                child: NetworkImageHandler(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  /// The amount being paid, stated rather than entered.
  ///
  /// The fee screen already resolved this from the installments, advance,
  /// relief and due charges, and [ManualFeePaymentArguments] carries the exact
  /// ids it settles. Letting it be retyped here would let the receipt claim one
  /// figure while the payment claims to clear those ids in full, which is a
  /// reconciliation the school would have to unpick by hand.
  ///
  /// It is deliberately *not* drawn as a filled, bordered box: that reads as a
  /// disabled input, which invites tapping and then gives no feedback. A plain
  /// label with the figure carrying the weight says "this is the amount"
  /// instead of "this is a field you may not use".
  Widget _buildPayableAmountRow() {
    return LabelledAmountRow(
      label: Utils.getTranslatedLabel(payableAmountKey),
      amount:
          "$_currencySymbol${widget.arguments.payableAmount.toStringAsFixed(2)}",
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(paymentDetailsKey),
        const SizedBox(height: 8.0),
        FeeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPayableAmountRow(),
              const SizedBox(height: 16.0),
              const FeeCardDivider(),
              const SizedBox(height: 16.0),
              BlocBuilder<ManualFeePaymentCubit, ManualFeePaymentState>(
                builder: (context, state) {
                  return AddFilesContainer(
                    fileNames: [
                      if (_receiptFile != null) _receiptFile!.name,
                    ],
                    onTapAddFiles: _pickFiles,
                    onRemoveFile: (_) => setState(() => _receiptFile = null),
                    noteTextAlign: TextAlign.center,
                    backgroundColor: onlineClassCardColor,
                    verticalPadding: 8.0,
                    //the receipt is already being uploaded; swapping it now
                    //would not change what the school receives
                    enabled: state is! ManualFeePaymentInProgress,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              const FeeCardDivider(),
              const SizedBox(height: 16.0),
              _buildNoteField(),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  /// Optional note the school sees alongside the receipt.
  ///
  /// Placed after the receipt because it is the last, least required thing the
  /// parent does — a transfer reference or which installment the money was
  /// meant for. It is never validated: an empty note is simply not sent.
  Widget _buildNoteField() {
    return BlocBuilder<ManualFeePaymentCubit, ManualFeePaymentState>(
      builder: (context, state) {
        final inProgress = state is ManualFeePaymentInProgress;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: secondaryStrokeColor),
          ),
          child: TextField(
            controller: _noteTextEditingController,
            //the note travels with the request already in flight; editing it
            //now would not change what the school receives
            enabled: !inProgress,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            //stopping the typing at the endpoint's limit is kinder than
            //refusing the payment once the receipt has already been uploaded
            inputFormatters: [
              LengthLimitingTextInputFormatter(manualPaymentNoteMaxLength),
            ],
            style: TextStyle(
              fontSize: 14.0,
              letterSpacing: 0.25,
              color: Theme.of(context).colorScheme.secondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: Utils.getTranslatedLabel(addNoteKey),
              hintStyle: const TextStyle(
                fontSize: 14.0,
                letterSpacing: 0.25,
                color: captionColor,
              ),
            ),
          ),
        );
      },
    );
  }

  ///[Sets the expectation that paying here does not clear the fee immediately]
  Widget _buildUnderReviewNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: warningContainerColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        Utils.getTranslatedLabel(manualPaymentUnderReviewNoteKey),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 16 / 12,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 2.0,
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
      ),
      child: BlocConsumer<ManualFeePaymentCubit, ManualFeePaymentState>(
        listener: _manualFeePaymentListener,
        builder: (context, state) {
          final inProgress = state is ManualFeePaymentInProgress;

          return CustomRoundedButton(
            height: 48.0,
            radius: 8.0,
            // CustomRoundedButton sizes off the full screen width, so the 16px
            // padding on each side has to be discounted or the button overflows.
            widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                MediaQuery.of(context).size.width,
            textSize: 16.0,
            fontWeight: FontWeight.w500,
            backgroundColor: Theme.of(context).colorScheme.primary,
            buttonTitle: Utils.getTranslatedLabel(submitPaymentKey),
            showBorder: false,
            //uploading the same receipt twice would file two payments for one
            //transfer, which the school then has to unpick
            child: inProgress
                ? CustomCircularProgressIndicator(
                    widthAndHeight: 20,
                    strokeWidth: 2,
                  )
                : null,
            onTap: _submitPayment,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manualPayment = _manualPaymentGateway;
    final isSubmitting = context.watch<ManualFeePaymentCubit>().state
        is ManualFeePaymentInProgress;

    return PopScope(
      //leaving mid upload would abandon a request the school may still receive
      canPop: !isSubmitting,
      child: Scaffold(
        //only offer the action when there is something to submit against
        bottomNavigationBar:
            manualPayment == null ? null : _buildSubmitButton(),
        body: Stack(
          children: [
            if (manualPayment == null)
              Padding(
                padding: EdgeInsets.only(
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                  ),
                ),
                child: NoDataContainer(titleKey: manualPaymentNotConfiguredKey),
              )
            else
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 24.0,
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSchoolInstructionCard(manualPayment),
                    _buildQrCard(manualPayment),
                    _buildPaymentDetailsCard(),
                    _buildUnderReviewNote(),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: CustomAppBar(title: Utils.getTranslatedLabel(feesKey)),
            ),
          ],
        ),
      ),
    );
  }
}
