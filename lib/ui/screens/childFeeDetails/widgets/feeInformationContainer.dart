import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/ui/widgets/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// a student info card followed by a "Due Date" card.
class FeeInformationContainer extends StatelessWidget {
  final ChildFeeDetails childFeeDetails;
  final Student child;

  /// Which side of the fee is on screen below this card.
  ///
  /// The card sits under the tab selector, so a parent reads its status as
  /// belonging to the tab they are on. Stating the compulsory settlement on the
  /// optional tab put a green "Paid" directly above optional fees marked "Under
  /// Review".
  final bool compulsory;

  const FeeInformationContainer({
    super.key,
    required this.child,
    required this.childFeeDetails,
    required this.compulsory,
  });

  /// Surface card wrapper (bg #f5f5f5, radius 8, padding 12) used by both cards.
  Widget _surfaceCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: child,
    );
  }

  /// Resolves the student photo URL.
  ///
  /// For the parent flow the child's image is provided under
  /// [Student.childUserDetails], while for a student's own session it lives on
  /// [Student.image]. We prefer whichever is non-empty so the avatar shows in
  /// both cases (matches the parent home screen which reads childUserDetails).
  String _studentImageUrl() {
    final childUserImage = child.childUserDetails?.image ?? "";
    if (childUserImage.trim().isNotEmpty) {
      return childUserImage;
    }
    return child.image ?? "";
  }

  /// The class and the session year the fee belongs to, on one line.
  ///
  /// Read together — "9 English • 2026" — because neither means much without
  /// the other, and keeping them as one line leaves the far side of the card to
  /// the status alone.
  String _classAndSessionLabel() {
    final classLabel = childFeeDetails.classDetails?.fullName ??
        "${childFeeDetails.classDetails?.name ?? ''} ${childFeeDetails.classDetails?.medium?.name ?? ''}"
            .trim();
    final sessionYear = (childFeeDetails.sessionYear?.name ?? '').trim();

    //either half can be missing, and a stranded separator looks like a fault
    return [classLabel, sessionYear]
        .where((part) => part.isNotEmpty)
        .join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final statusKey = compulsory
        ? childFeeDetails.getFeePaymentStatus()
        : childFeeDetails.getOptionalFeePaymentStatus();

    return Column(
      children: [
        // ---- Student info card ----
        _surfaceCard(
          context,
          child: Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ),
                child: CustomUserProfileImageWidget(
                  profileUrl: _studentImageUrl(),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.getFullName(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      _classAndSessionLabel(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        letterSpacing: 0.4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              //where this side of the fee stands, stated the same way the
              //payment history states what became of each payment. Absent when
              //the side holds nothing — a school with no optional fees has no
              //optional status, and inventing one would say more than is known
              if (statusKey != null) ...[
                const SizedBox(width: 12.0),
                StatusChip(
                  label: Utils.getTranslatedLabel(statusKey),
                  color: Utils.getFeePaymentStatusColor(statusKey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        // ---- Due Date card ----
        _surfaceCard(
          context,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Utils.getTranslatedLabel(dueDateKey),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                childFeeDetails.dueDate ?? "-",
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
