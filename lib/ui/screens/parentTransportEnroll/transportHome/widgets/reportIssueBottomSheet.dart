import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/cubits/tripReportCubit.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';

// Wrapper widget to handle the Scaffold and BlocProvider
class _ReportIssueBottomSheetWrapper extends StatelessWidget {
  final int tripId;
  final BuildContext rootContext;

  const _ReportIssueBottomSheetWrapper({
    required this.tripId,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocProvider(
        create: (context) => TripReportCubit(),
        child: ReportIssueBottomSheet(
          tripId: tripId,
          rootContext: rootContext,
        ),
      ),
    );
  }
}

class ReportIssueBottomSheet extends StatefulWidget {
  final int tripId;
  final BuildContext rootContext;

  const ReportIssueBottomSheet({
    super.key,
    required this.tripId,
    required this.rootContext,
  });

  static void show(BuildContext context, {required int tripId}) {
    // Store the root context for showing SnackBars
    final rootContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => _ReportIssueBottomSheetWrapper(
        tripId: tripId,
        rootContext: rootContext,
      ),
    );
  }

  @override
  State<ReportIssueBottomSheet> createState() => _ReportIssueBottomSheetState();
}

class _ReportIssueBottomSheetState extends State<ReportIssueBottomSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedIssue;
  String? _previousAutoFilledText;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    // Validate inputs
    if (_selectedIssue == null || _selectedIssue!.isEmpty) {
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(Utils.getTranslatedLabel(selectIssueTypeKey)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Text(Utils.getTranslatedLabel(enterIssueKey)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Submit report
    context.read<TripReportCubit>().submitReport(
          tripId: widget.tripId,
          description: description,
        );
  }

  void _selectIssue(String issueKey) {
    setState(() {
      _selectedIssue = issueKey;
    });

    final currentText = _descriptionController.text.trim();
    final translatedIssue = Utils.getTranslatedLabel(issueKey);

    // Get all translated issue labels for comparison
    final translatedIssueLabels = transportReportIssueLabelKeys
        .map((key) => Utils.getTranslatedLabel(key))
        .toList();

    // Check if current text is empty, matches previous auto-filled text,
    // or is one of the predefined issue labels
    final shouldReplace = currentText.isEmpty ||
        currentText == _previousAutoFilledText ||
        translatedIssueLabels.contains(currentText);

    if (shouldReplace) {
      // Replace with new issue label
      _descriptionController.text = translatedIssue;
      _previousAutoFilledText = translatedIssue;
    } else {
      // User has added custom text, so we keep it and just update selection
      // This preserves user's custom description while updating the selected issue type
      _previousAutoFilledText = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripReportCubit, TripReportState>(
      listener: (context, state) {
        if (state is TripReportSubmitSuccess) {
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }

        if (state is TripReportSubmitFailure) {
          ScaffoldMessenger.of(widget.rootContext).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildDescriptionText(),
                        const SizedBox(height: 20),
                        _buildIssueTypeButtons(),
                        const SizedBox(height: 24),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Utils.getTranslatedLabel(reportIssuesKey),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionText() {
    return Text(
      Utils.getTranslatedLabel(raiseAnySchoolTransportDelaysKey),
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.4,
      ),
    );
  }

  Widget _buildIssueTypeButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for each button (2 per row)
        final buttonWidth = (constraints.maxWidth - 12) /
            2; // 12 is the spacing between buttons

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: transportReportIssueLabelKeys.map((issueKey) {
            final isSelected = _selectedIssue == issueKey;
            final translatedLabel = Utils.getTranslatedLabel(issueKey);

            return SizedBox(
              width: buttonWidth,
              child: GestureDetector(
                onTap: () => _selectIssue(issueKey),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    translatedLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: Utils.getTranslatedLabel(enterIssueKey),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<TripReportCubit, TripReportState>(
      builder: (context, state) {
        final isSubmitting = state is TripReportSubmitting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              disabledBackgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    Utils.getTranslatedLabel(submitKey),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
