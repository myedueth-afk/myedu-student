import 'dart:io';

import 'package:eschool/ui/widgets/attachmentSourceBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Picks attachments in a way that reaches the photo library as well as the
/// files browser.
///
/// iOS keeps the two behind different system pickers. `file_picker` asked for a
/// list of extensions opens `UIDocumentPickerViewController`, which browses the
/// Files app and cannot see the photo library at all — so a parent whose
/// receipt was a screenshot had no way to attach it, and the picker looked
/// broken rather than limited.
///
/// Android's picker already reaches both from one tap, so it is left exactly as
/// it was: no extra sheet, no change in behaviour.
class AttachmentPicker {
  const AttachmentPicker._();

  /// Bounds on an image taken from the library or the camera.
  ///
  /// Passing them is what makes the iOS plugin re-encode what it hands back,
  /// which matters more than the size: an iPhone stores photos as HEIC, and
  /// the fee and leave endpoints accept jpg/png/pdf/doc but not that. The
  /// bounds are generous because the picture is usually a receipt, and a
  /// receipt has to stay readable.
  static const double _maxImageDimension = 2000.0;
  static const int _imageQuality = 85;

  /// Overrides the platform decision in tests, where [Platform] reports the
  /// host machine rather than the device the app runs on.
  @visibleForTesting
  static bool? debugAsksForSource;

  /// Whether the source has to be asked for before anything can be picked.
  static bool get asksForSource =>
      debugAsksForSource ?? (!kIsWeb && Platform.isIOS);

  /// The files the user chose, or an empty list when they backed out.
  ///
  /// [allowedExtensions] filters the documents browser and is checked again on
  /// the way back: the photo library returns whatever the camera wrote, and a
  /// file the endpoint will refuse is better caught here than after an upload.
  static Future<List<PlatformFile>> pick({
    required BuildContext context,
    required List<String> allowedExtensions,
    bool allowMultiple = false,
    bool allowCamera = true,
  }) async {
    final source = asksForSource
        ? await Utils.showBottomSheet(
            context: context,
            child: AttachmentSourceBottomsheet(allowCamera: allowCamera),
          )
        : AttachmentSource.files;

    if (source is! AttachmentSource) {
      //the sheet was dismissed
      return const [];
    }

    final picked = source == AttachmentSource.files
        ? await _pickDocuments(
            allowedExtensions: allowedExtensions,
            allowMultiple: allowMultiple,
          )
        : await _pickImages(
            fromCamera: source == AttachmentSource.camera,
            allowMultiple: allowMultiple,
          );

    final supported =
        picked.where((file) => _isSupported(file, allowedExtensions)).toList();

    //saying so beats a silent no-op, and beats an upload the endpoint refuses
    if (supported.length != picked.length && context.mounted) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            Utils.getTranslatedLabel(onlyImageOrDocumentFilesAllowedKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }

    return supported;
  }

  static Future<List<PlatformFile>> _pickDocuments({
    required List<String> allowedExtensions,
    required bool allowMultiple,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    //the picker returns null when the sheet is dismissed
    return result?.files ?? const [];
  }

  static Future<List<PlatformFile>> _pickImages({
    required bool fromCamera,
    required bool allowMultiple,
  }) async {
    final picker = ImagePicker();
    final picked = <XFile>[];

    if (fromCamera) {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageDimension,
        maxHeight: _maxImageDimension,
        imageQuality: _imageQuality,
      );
      if (photo != null) {
        picked.add(photo);
      }
    } else if (allowMultiple) {
      picked.addAll(await picker.pickMultiImage(
        maxWidth: _maxImageDimension,
        maxHeight: _maxImageDimension,
        imageQuality: _imageQuality,
      ));
    } else {
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageDimension,
        maxHeight: _maxImageDimension,
        imageQuality: _imageQuality,
      );
      if (photo != null) {
        picked.add(photo);
      }
    }

    return Future.wait(picked.map(toPlatformFile));
  }

  /// An [XFile] from the image picker as the [PlatformFile] the upload code and
  /// the file list widgets already speak.
  @visibleForTesting
  static Future<PlatformFile> toPlatformFile(XFile file) async => PlatformFile(
        name: file.name,
        path: file.path,
        size: await file.length(),
      );

  /// Whether the endpoint will accept this file, by its extension.
  ///
  /// Read off the name rather than [PlatformFile.extension] so a file the image
  /// picker named without one is refused rather than quietly sent.
  @visibleForTesting
  static bool isSupported(String fileName, List<String> allowedExtensions) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) {
      return false;
    }

    final extension = fileName.substring(dot + 1).toLowerCase();
    return allowedExtensions.map((e) => e.toLowerCase()).contains(extension);
  }

  static bool _isSupported(PlatformFile file, List<String> allowedExtensions) =>
      isSupported(file.name, allowedExtensions);
}
