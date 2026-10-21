import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

///[Where an attachment is being taken from]
enum AttachmentSource { gallery, camera, files }

/// Asks which of the two places an attachment is coming from.
///
/// Only shown where the platform keeps them apart — see [AttachmentPicker].
/// Modelled on the chat attachment sheet so the app asks this question the same
/// way wherever it asks it.
class AttachmentSourceBottomsheet extends StatelessWidget {
  ///[A receipt can be photographed on the spot; a leave note usually cannot]
  final bool allowCamera;

  const AttachmentSourceBottomsheet({super.key, this.allowCamera = true});

  Widget _buildSource(
    BuildContext context, {
    required String titleKey,
    required String iconPath,
    required AttachmentSource source,
    required double width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Get.back(result: source),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: width,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter:
                  ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(height: 5),
            Text(
              Utils.getTranslatedLabel(titleKey),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * (0.075),
        vertical: size.height * (0.05),
      ),
      width: size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * (allowCamera ? 0.31 : 0.48);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSource(
                context,
                titleKey: galleryKey,
                iconPath: Utils.getImagePath("chat_gallery.svg"),
                source: AttachmentSource.gallery,
                width: width,
              ),
              if (allowCamera)
                _buildSource(
                  context,
                  titleKey: cameraKey,
                  iconPath: Utils.getImagePath("camera_icon.svg"),
                  source: AttachmentSource.camera,
                  width: width,
                ),
              _buildSource(
                context,
                titleKey: documentKey,
                iconPath: Utils.getImagePath("document.svg"),
                source: AttachmentSource.files,
                width: width,
              ),
            ],
          );
        },
      ),
    );
  }
}
