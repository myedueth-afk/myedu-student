import 'package:eschool/data/repositories/tripReportRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TripReportState {}

class TripReportInitial extends TripReportState {}

class TripReportSubmitting extends TripReportState {}

class TripReportSubmitSuccess extends TripReportState {
  final String message;

  TripReportSubmitSuccess({required this.message});
}

class TripReportSubmitFailure extends TripReportState {
  final String errorMessage;

  TripReportSubmitFailure({required this.errorMessage});
}

class TripReportCubit extends Cubit<TripReportState> {
  final TripReportRepository _repository = TripReportRepository();

  TripReportCubit() : super(TripReportInitial());

  Future<void> submitReport({
    required int tripId,
    required String description,
  }) async {
    emit(TripReportSubmitting());

    try {
      final result = await _repository.submitTripReport(
        routeVehicleHistoryId: tripId,
        description: description,
      );

      emit(TripReportSubmitSuccess(
        message: result['message'] ?? 'Report submitted successfully',
      ));
    } catch (e) {
      emit(TripReportSubmitFailure(
        errorMessage: e.toString(),
      ));
    }
  }

  void resetState() {
    emit(TripReportInitial());
  }
}
