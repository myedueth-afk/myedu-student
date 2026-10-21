import 'package:eschool/data/models/certificateAssignment.dart';
import 'package:eschool/data/repositories/certificateRepository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// States for the certificates cubit.
abstract class CertificatesState {}

class CertificatesInitial extends CertificatesState {}

class CertificatesFetchInProgress extends CertificatesState {}

class CertificatesFetchSuccess extends CertificatesState {
  final List<CertificateAssignment> certificates;

  CertificatesFetchSuccess({required this.certificates});
}

class CertificatesFetchFailure extends CertificatesState {
  final String errorMessage;

  CertificatesFetchFailure(this.errorMessage);
}

/// Cubit managing the certificate assignments list.
class CertificatesCubit extends Cubit<CertificatesState> {
  final CertificateRepository _certificateRepository;

  CertificatesCubit(this._certificateRepository) : super(CertificatesInitial());

  Future<void> fetchCertificates({int? childId}) async {
    debugPrint('CertificatesCubit: fetchCertificates called');
    emit(CertificatesFetchInProgress());
    try {
      final certificates =
          await _certificateRepository.fetchCertificateAssignments(
        childId: childId,
      );
      debugPrint(
        'CertificatesCubit: fetched ${certificates.length} certificates',
      );
      emit(CertificatesFetchSuccess(certificates: certificates));
    } catch (e) {
      debugPrint('CertificatesCubit: error - $e');
      emit(CertificatesFetchFailure(e.toString()));
    }
  }

  List<CertificateAssignment> getCertificates() {
    if (state is CertificatesFetchSuccess) {
      return (state as CertificatesFetchSuccess).certificates;
    }
    return [];
  }
}
