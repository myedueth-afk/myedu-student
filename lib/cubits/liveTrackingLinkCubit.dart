import 'package:eschool/data/models/liveTrackingLink.dart';
import 'package:eschool/data/repositories/liveRouteRepository.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LiveTrackingLinkState {}

class LiveTrackingLinkInitial extends LiveTrackingLinkState {}

class LiveTrackingLinkFetchInProgress extends LiveTrackingLinkState {
  /// A renewal happens behind a map that is already on screen, so the screen
  /// keeps showing the old page instead of dropping back to a spinner.
  final bool isRenewal;

  LiveTrackingLinkFetchInProgress({this.isRenewal = false});
}

class LiveTrackingLinkFetchSuccess extends LiveTrackingLinkState {
  final LiveTrackingLink link;

  LiveTrackingLinkFetchSuccess(this.link);
}

class LiveTrackingLinkFetchFailure extends LiveTrackingLinkState {
  /// Either a message the backend wrote ("No active transport plan") or one of
  /// the app's own error codes. [Utils.getErrorMessageFromErrorCode] tells the
  /// two apart, so both can be shown without branching here.
  final String errorMessage;

  LiveTrackingLinkFetchFailure(this.errorMessage);
}

/// Mints the links that open the web live-tracking page in a WebView.
///
/// Deliberately not merged into [LiveRouteCubit]: that one polls the native
/// stop timeline, while this fires once per screen open and once per renewal.
class LiveTrackingLinkCubit extends Cubit<LiveTrackingLinkState> {
  final LiveRouteRepository _repository = LiveRouteRepository();

  LiveTrackingLinkCubit() : super(LiveTrackingLinkInitial());

  Future<void> createLink({
    required int userId,
    int? tripId,
    bool isRenewal = false,
  }) async {
    emit(LiveTrackingLinkFetchInProgress(isRenewal: isRenewal));

    try {
      final link = await _repository.createLiveTrackingLink(
        userId: userId,
        tripId: tripId,
      );
      if (isClosed) return;

      // A 200 with no url is not something the screen can recover from by
      // showing an empty WebView, so it is reported as a failure with a retry.
      if (!link.isUsable) {
        emit(
          LiveTrackingLinkFetchFailure(
            ErrorMessageKeysAndCode.defaultErrorMessageCode,
          ),
        );
        return;
      }

      emit(LiveTrackingLinkFetchSuccess(link));
    } catch (e) {
      if (isClosed) return;
      emit(LiveTrackingLinkFetchFailure(e.toString()));
    }
  }
}
