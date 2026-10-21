import 'package:dotted_border/dotted_border.dart';
import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/ui/widgets/downloadFileButton.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialWithDownloadButtonContainer extends StatelessWidget {
  final BoxConstraints boxConstraints;
  final StudyMaterial studyMaterial;
  const StudyMaterialWithDownloadButtonContainer({
    Key? key,
    required this.boxConstraints,
    required this.studyMaterial,
  }) : super(key: key);

  Future<void> _handleOtherLinkTap() async {
    final Uri uri = Uri.parse(studyMaterial.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleTap(BuildContext context) {
    if (studyMaterial.isOtherLink) {
      _handleOtherLinkTap();
    } else if (studyMaterial.isAudio) {
      Utils.openAudioPlayerBottomsheet(
        context: context,
        studyMaterial: studyMaterial,
      );
    } else {
      Utils.openDownloadBottomsheet(
        context: context,
        storeInExternalStorage: false,
        studyMaterial: studyMaterial,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: DottedBorder(
          borderType: BorderType.RRect,
          dashPattern: const [10, 10],
          radius: const Radius.circular(10.0),
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    studyMaterial.isOtherLink
                        ? studyMaterial.fileUrl
                        : studyMaterial.fileName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (studyMaterial.isAudio) ...[
                  _buildPlayAudioButton(context),
                  const SizedBox(width: 8),
                ],
                studyMaterial.isOtherLink
                    ? _buildLinkButton(context)
                    : DownloadFileButton(
                        studyMaterial: studyMaterial,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayAudioButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => Utils.openAudioPlayerBottomsheet(
        context: context,
        studyMaterial: studyMaterial,
      ),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link,
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Open',
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
