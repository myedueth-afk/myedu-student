import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class ReportDivider extends StatelessWidget {
  const ReportDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(
        color: Utils.getColorScheme(context).onSurface.withValues(alpha: 0.1),
        height: 1,
        thickness: 1.5,
      ),
    );
  }
}
