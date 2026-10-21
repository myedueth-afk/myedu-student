import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class ReportCardTitle extends StatelessWidget {
  final String title;

  const ReportCardTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Utils.getColorScheme(context).onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
