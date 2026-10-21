import 'dart:io';

import 'package:eschool/data/repositories/studentRepository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadStudentIdCardState {}

class DownloadStudentIdCardInitial extends DownloadStudentIdCardState {}

class DownloadStudentIdCardInProgress extends DownloadStudentIdCardState {}

class DownloadStudentIdCardSuccess extends DownloadStudentIdCardState {
  final String downloadedFilePath;

  DownloadStudentIdCardSuccess({required this.downloadedFilePath});
}

class DownloadStudentIdCardFailure extends DownloadStudentIdCardState {
  final String errorMessage;

  DownloadStudentIdCardFailure(this.errorMessage);
}

class DownloadStudentIdCardCubit extends Cubit<DownloadStudentIdCardState> {
  final StudentRepository _studentRepository;

  DownloadStudentIdCardCubit(this._studentRepository)
      : super(DownloadStudentIdCardInitial());

  void downloadStudentIdCard({int? userId}) async {
    try {
      emit(DownloadStudentIdCardInProgress());

      final path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          userId != null ? "id-card-$userId.pdf" : "id-card.pdf";
      final String filePath = "$path/IdCards/$fileName";

      final File file = File(filePath);

      final pdfBytes = await _studentRepository.downloadIdCard(userId: userId);
      await file.create(recursive: true);

      await file.writeAsBytes(pdfBytes);
      emit(DownloadStudentIdCardSuccess(downloadedFilePath: filePath));
    } catch (e) {
      emit(DownloadStudentIdCardFailure(e.toString()));
    }
  }
}
