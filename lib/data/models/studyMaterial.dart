enum StudyMaterialType { file, youtubeVideo, uploadedVideoUrl, other }

StudyMaterialType getStudyMaterialType(int type) {
  if (type == 1) {
    return StudyMaterialType.file;
  }
  if (type == 2) {
    return StudyMaterialType.youtubeVideo;
  }
  if (type == 3) {
    return StudyMaterialType.uploadedVideoUrl;
  }

  return StudyMaterialType.other;
}

class StudyMaterial {
  late final StudyMaterialType studyMaterialType;

  late final int id;
  late final String fileName;
  late final String fileThumbnail;
  late final String fileUrl;
  late final String fileExtension;
  late final String typeDetail;

  StudyMaterial({
    required this.fileExtension,
    required this.fileUrl,
    required this.fileThumbnail,
    required this.fileName,
    required this.id,
    required this.studyMaterialType,
    required this.typeDetail,
  });

  StudyMaterial.fromJson(Map<String, dynamic> json) {
    studyMaterialType = getStudyMaterialType(int.parse(json['type'] ?? "0"));

    id = json['id'] ?? 0;
    fileName = json['file_name'] ?? "";
    fileThumbnail = json['file_thumbnail'] ?? "";
    fileUrl = json['file_url'] ?? "";
    fileExtension = json['file_extension'] ?? "";
    typeDetail = json['type_detail'] ?? "";
  }

  bool get isOtherLink => typeDetail == "Other Link";

  /// Uploaded file extensions that are streamed in the in-app audio player.
  /// `mpga` is what Laravel's mime-based extension guess returns for mp3.
  static const Set<String> audioFileExtensions = {
    'mp3',
    'mpga',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'oga',
    'opus',
    'flac',
    'amr',
  };

  bool get isAudio {
    if (studyMaterialType != StudyMaterialType.file) return false;

    var extension = fileExtension;
    if (extension.isEmpty) {
      final path = Uri.tryParse(fileUrl)?.path ?? "";
      final dotIndex = path.lastIndexOf('.');
      extension = dotIndex == -1 ? "" : path.substring(dotIndex + 1);
    }

    return audioFileExtensions
        .contains(extension.replaceFirst('.', '').toLowerCase());
  }
}
