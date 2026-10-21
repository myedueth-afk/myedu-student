import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/ui/widgets/downloadFileButton.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FilesContainer extends StatefulWidget {
  final List<StudyMaterial> files;
  const FilesContainer({Key? key, required this.files}) : super(key: key);

  @override
  State<FilesContainer> createState() => _FilesContainerState();
}

class _FilesContainerState extends State<FilesContainer> {
  Widget _buildFileDetailsContainer(StudyMaterial file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Animate(
        effects: customItemFadeAppearanceEffects(),
        child: GestureDetector(
          onTap: () {
            Utils.openDownloadBottomsheet(
              context: context,
              storeInExternalStorage: false,
              studyMaterial: file,
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.1),
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                )
              ],
            ),
            constraints: const BoxConstraints(
              minHeight: 60,
            ),
            width: MediaQuery.of(context).size.width * (0.85),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${file.fileName}.${file.fileExtension}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DownloadFileButton(
                      studyMaterial: file,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.files.isEmpty
          ? [const NoDataContainer(titleKey: noFilesUploadedKey)]
          : widget.files
              .map((file) => _buildFileDetailsContainer(file))
              .toList(),
    );
  }
}
