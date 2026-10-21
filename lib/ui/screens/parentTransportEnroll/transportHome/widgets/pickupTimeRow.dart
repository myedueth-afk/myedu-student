import 'package:eschool/ui/screens/parentTransportEnroll/transportHome/widgets/commonTransportWidgets.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PickupTimeRow extends StatelessWidget {
  /// Opens the live map — the primary action, hence the filled button.
  final VoidCallback onTap;

  /// Opens the stop-by-stop timeline, which is also the way in to reporting a
  /// problem with the trip. Optional so the row still works without it.
  final VoidCallback? onTapRouteDetails;

  final String? pickupTime;
  const PickupTimeRow({
    super.key,
    required this.onTap,
    this.onTapRouteDetails,
    this.pickupTime,
  });

  @override
  Widget build(BuildContext context) {
    // Check if pickup time indicates the bus has reached
    final bool hasReached = pickupTime?.contains('Reached') ?? false;

    // Format the value - only show "(Estimated)" if not reached
    final String displayValue = hasReached
        ? pickupTime ?? ''
        : "${pickupTime ?? ''} (${Utils.getTranslatedLabel(estimatedKey)})";

    return Row(
      children: [
        Expanded(
          child: LabelValue(
            label: Utils.getTranslatedLabel(pickupTimeKey),
            value: displayValue,
            smallValueStyle: true,
          ),
        ),
        if (onTapRouteDetails != null) ...[
          InkWell(
            onTap: onTapRouteDetails,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _actionColor, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.alt_route_rounded,
                  size: 20,
                  color: _actionColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _actionColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                Utils.getImagePath('directions.svg'),
                width: 20,
                height: 20,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const Color _actionColor = Color(0xFF1F4B63);
}
