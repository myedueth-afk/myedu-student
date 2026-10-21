import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:flutter/material.dart';

/// School code input, rendered as nothing on a build locked to one school.
///
/// Read the value with [SchoolBuildConfig.resolveSchoolCode], not the controller.
class SchoolCodeFieldContainer extends StatelessWidget {
  const SchoolCodeFieldContainer({
    required this.textEditingController,
    this.bottomPadding,
    Key? key,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (SchoolBuildConfig.hasFixedSchoolCode) {
      return const SizedBox.shrink();
    }

    return CustomTextFieldContainer(
      hideText: false,
      hintTextKey: "schoolCode",
      bottomPadding: bottomPadding,
      textEditingController: textEditingController,
    );
  }
}
