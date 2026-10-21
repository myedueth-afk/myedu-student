import 'package:dotted_border/dotted_border.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// Dashed "Add Files" target with the allowed-types note and the list of files
/// picked so far, each removable.
///
/// Shared by every screen that lets the user attach supporting documents (apply
/// leave, manual fee payment) so the upload affordance stays identical
/// everywhere. The caller owns the file list and the picker itself — this
/// widget only renders and reports taps, which keeps the allowed extensions and
/// the error handling with the flow that knows what the endpoint accepts.
class AddFilesContainer extends StatelessWidget {
  /// Names of the files already picked, in the order they were added.
  final List<String> fileNames;

  final VoidCallback onTapAddFiles;

  /// Called with the index of the file the user removed.
  final ValueChanged<int> onRemoveFile;

  /// Note under the dashed target. Defaults to the shared
  /// "only image or document files" wording.
  final String noteLabelKey;

  /// The leave form reads as a left aligned column, the manual payment card
  /// centres its note under the target — so the caller decides.
  final TextAlign noteTextAlign;

  /// Fill behind the dashed target. Transparent on the leave form, tinted
  /// inside the manual payment card where it sits on a white card.
  final Color? backgroundColor;

  /// Height of the dashed target. The leave form gives it more room than the
  /// denser manual payment card does.
  final double verticalPadding;

  /// Set to false while a submission is in flight, so files cannot be swapped
  /// out from under a request that is already using them.
  final bool enabled;

  const AddFilesContainer({
    super.key,
    required this.fileNames,
    required this.onTapAddFiles,
    required this.onRemoveFile,
    this.noteLabelKey = onlyImageOrDocumentFilesAllowedKey,
    this.noteTextAlign = TextAlign.start,
    this.backgroundColor,
    this.verticalPadding = 16.0,
    this.enabled = true,
  });

  static const TextStyle _noteTextStyle = TextStyle(
    color: captionColor,
    fontSize: 12.0,
    height: 16 / 12,
    letterSpacing: 0.4,
  );

  Widget _buildAddFilesButton(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTapAddFiles : null,
      behavior: HitTestBehavior.opaque,
      child: DottedBorder(
        borderType: BorderType.RRect,
        dashPattern: const [6, 4],
        radius: const Radius.circular(8.0),
        strokeWidth: 1,
        color: secondaryStrokeColor,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle,
                size: 22.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              CustomTextContainer(
                textKey: addFilesKey,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFile(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20.0,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              fileNames[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: enabled ? () => onRemoveFile(index) : null,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close,
              size: 20.0,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddFilesButton(context),
        const SizedBox(height: 8.0),
        SizedBox(
          width: double.infinity,
          child: CustomTextContainer(
            textKey: noteLabelKey,
            textAlign: noteTextAlign,
            style: _noteTextStyle,
          ),
        ),
        ...List.generate(
          fileNames.length,
          (index) => _buildSelectedFile(context, index),
        ),
      ],
    );
  }
}
