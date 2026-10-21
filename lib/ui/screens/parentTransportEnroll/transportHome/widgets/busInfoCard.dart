import 'package:eschool/data/models/transportDashboard.dart';
import 'package:eschool/ui/screens/parentTransportEnroll/transportHome/widgets/commonTransportWidgets.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class BusInfoCard extends StatelessWidget {
  final BusInfo? busInfo;

  const BusInfoCard({super.key, this.busInfo});

  @override
  Widget build(BuildContext context) {
    return EnrollCard(
      title: busInfoKey,
      trailing: const SizedBox(),
      children: [
        Text(
          busInfo != null
              ? '${Utils.getTranslatedLabel(busNoKey)} : ${busInfo!.registration}'
              : 'N/A',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        PersonRow(
          label: driverKey,
          name: busInfo?.driver?.name ?? 'N/A',
          phone: busInfo?.driver?.phone,
          avatar: busInfo?.driver?.avatar,
          userId: busInfo?.driver?.id,
        ),
        PersonRow(
          label: attenderKey,
          name: busInfo?.attender?.name ?? 'N/A',
          phone: busInfo?.attender?.phone,
          avatar: busInfo?.attender?.avatar,
          userId: busInfo?.attender?.id,
        ),
      ],
    );
  }
}
