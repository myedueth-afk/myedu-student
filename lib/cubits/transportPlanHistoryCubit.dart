import 'package:eschool/data/models/transportPlanDetails.dart';
import 'package:eschool/data/repositories/transportRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TransportPlanHistoryState {}

class TransportPlanHistoryInitial extends TransportPlanHistoryState {}

class TransportPlanHistoryFetchInProgress extends TransportPlanHistoryState {}

class TransportPlanHistoryFetchSuccess extends TransportPlanHistoryState {
  final List<TransportPlanDetails> plans;

  TransportPlanHistoryFetchSuccess({required this.plans});
}

class TransportPlanHistoryFetchFailure extends TransportPlanHistoryState {
  final String errorMessage;

  TransportPlanHistoryFetchFailure(this.errorMessage);
}

class TransportPlanHistoryCubit extends Cubit<TransportPlanHistoryState> {
  final TransportRepository _transportRepository = TransportRepository();

  TransportPlanHistoryCubit() : super(TransportPlanHistoryInitial());

  void fetchPlans({required int userId}) async {
    try {
      emit(TransportPlanHistoryFetchInProgress());
      final plans =
          await _transportRepository.getTransportPlanHistory(userId: userId);
      emit(TransportPlanHistoryFetchSuccess(plans: plans));
    } catch (e) {
      emit(TransportPlanHistoryFetchFailure(e.toString()));
    }
  }
}
