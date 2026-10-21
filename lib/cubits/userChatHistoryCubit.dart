import 'package:eschool/data/models/chatUserRole.dart';
import 'package:eschool/data/models/userChatHistory.dart';
import 'package:eschool/data/repositories/chatRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UserChatHistoryState {}

class UserChatHistoryInitial extends UserChatHistoryState {}

class UserChatHistoryFetchInProgress extends UserChatHistoryState {}

class UserChatHistoryFetchSuccess extends UserChatHistoryState {
  final UserChatHistory userChatHistory;
  final bool loadMore;

  UserChatHistoryFetchSuccess({
    required this.userChatHistory,
    this.loadMore = false,
  });
}

class UserChatHistoryFetchFailure extends UserChatHistoryState {
  final String errorMessage;

  UserChatHistoryFetchFailure(this.errorMessage);
}

class UserChatHistoryCubit extends Cubit<UserChatHistoryState> {
  UserChatHistoryCubit() : super(UserChatHistoryInitial());

  final ChatRepository _chatRepository = ChatRepository();

  void fetchUserChatHistory({required ChatUserRole role, int page = 1}) async {
    emit(UserChatHistoryFetchInProgress());

    await _chatRepository
        .getUserChatHistory(role: role, page: page)
        .then(
          (userChatHistory) => emit(
            UserChatHistoryFetchSuccess(userChatHistory: userChatHistory),
          ),
        )
        .catchError(
          (Object e) => emit(UserChatHistoryFetchFailure(e.toString())),
        );
  }

  bool get hasMore {
    if (state is UserChatHistoryFetchSuccess) {
      final history = (state as UserChatHistoryFetchSuccess).userChatHistory;

      return history.currentPage < history.lastPage;
    } else {
      return false;
    }
  }

  void fetchMoreUserChatHistory({required ChatUserRole role}) async {
    if (state is UserChatHistoryFetchSuccess &&
        !(state as UserChatHistoryFetchSuccess).loadMore) {
      final oldHistory = (state as UserChatHistoryFetchSuccess).userChatHistory;

      emit(UserChatHistoryFetchSuccess(
        userChatHistory: oldHistory,
        loadMore: true,
      ));

      await _chatRepository
          .getUserChatHistory(
        role: role,
        page: oldHistory.currentPage + 1,
      )
          .then(
        (userChatHistory) {
          final newContacts = oldHistory.chatContacts
            ..addAll(userChatHistory.chatContacts);

          emit(
            UserChatHistoryFetchSuccess(
              userChatHistory:
                  userChatHistory.copyWith(chatContacts: newContacts),
              loadMore: false,
            ),
          );
        },
      ).catchError(
        (Object e) {
          emit(UserChatHistoryFetchFailure(e.toString()));
        },
      );
    }
  }

  void messageReceived({
    required String from,
    required String message,
    required String updatedAt,
    required bool incrementUnreadCount,
  }) async {
    if (state is UserChatHistoryFetchSuccess) {
      final history = (state as UserChatHistoryFetchSuccess).userChatHistory;

      final chatContact = history.chatContacts
          .where((e) => e.user.id.toString() == from)
          .firstOrNull;

      /// message received from chat contact that is not in history
      if (chatContact == null) return;

      // Format the socket updatedAt into the same dd/MM/yyyy HH:mm format
      // used by the last_message_time API field so the UI stays consistent.
      String? formattedTime;
      try {
        final dt = DateTime.parse(updatedAt);
        final dd = dt.day.toString().padLeft(2, '0');
        final mm = dt.month.toString().padLeft(2, '0');
        final yyyy = dt.year.toString();
        final hh = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        formattedTime = '$dd/$mm/$yyyy $hh:$min';
      } catch (_) {
        formattedTime = updatedAt;
      }

      final updatedContact = chatContact.copyWith(
        lastMessage: message,
        updatedAt: updatedAt,
        lastMessageTime: formattedTime,
        unreadCount: incrementUnreadCount ? chatContact.unreadCount + 1 : null,
        hasAttachment:
            false, // Clear hasAttachment when a text message is received
      );

      final newContacts = history.chatContacts
          .map((e) => e.receiverId.toString() == from ? e = updatedContact : e)
          .toList();

      emit(
        UserChatHistoryFetchSuccess(
          userChatHistory: history.copyWith(chatContacts: newContacts),
        ),
      );
    }
  }

  void updateUnreadCount(int receiverId, int count) {
    if (state is UserChatHistoryFetchSuccess) {
      final history = (state as UserChatHistoryFetchSuccess).userChatHistory;

      final chatContact = history.chatContacts
          .where((e) => e.user.id == receiverId)
          .firstOrNull;

      /// message received from a chat contact that is not in the history
      if (chatContact == null) return;

      final updatedContact = chatContact.copyWith(
        unreadCount: (chatContact.unreadCount - count < 0
            ? 0
            : chatContact.unreadCount - count),
      );

      final newContacts = history.chatContacts
          .map((e) => e.user.id == receiverId ? e = updatedContact : e)
          .toList();

      emit(
        UserChatHistoryFetchSuccess(
          userChatHistory: history.copyWith(chatContacts: newContacts),
        ),
      );
    }
  }

  void updateLastMessage(
    int receiverId,
    String lastMessage,
    DateTime lastMessageTime,
  ) {
    if (state is UserChatHistoryFetchSuccess) {
      final history = (state as UserChatHistoryFetchSuccess).userChatHistory;

      final chatContact = history.chatContacts
          .where((e) => e.user.id == receiverId)
          .firstOrNull;

      /// message received from a chat contact that is not in the history
      if (chatContact == null) return;

      // Parse the existing lastMessageTime (format: "dd/MM/yyyy HH:mm") to
      // determine whether the incoming message is newer.
      DateTime? existingTime;
      final rawTime = chatContact.lastMessageTime ?? chatContact.updatedAt;
      try {
        // Try dd/MM/yyyy HH:mm (the new last_message_time format)
        final parts = rawTime.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('/');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length == 2) {
            final day = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            existingTime = DateTime(year, month, day, hour, minute);
          }
        }
      } catch (_) {
        // Fall back to ISO-8601 (e.g. value stored by socket update)
        try {
          existingTime = DateTime.tryParse(rawTime);
        } catch (_) {}
      }

      if (existingTime == null || lastMessageTime.isAfter(existingTime)) {
        // Format lastMessageTime as "dd/MM/yyyy HH:mm" to match the API field.
        final dd = lastMessageTime.day.toString().padLeft(2, '0');
        final mm = lastMessageTime.month.toString().padLeft(2, '0');
        final yyyy = lastMessageTime.year.toString();
        final hh = lastMessageTime.hour.toString().padLeft(2, '0');
        final min = lastMessageTime.minute.toString().padLeft(2, '0');
        final formattedTime = '$dd/$mm/$yyyy $hh:$min';

        final updatedContact = chatContact.copyWith(
          lastMessage: lastMessage,
          lastMessageTime: formattedTime,
          hasAttachment:
              false, // Clear hasAttachment when a text message is updated
        );

        final newContacts = history.chatContacts
            .map((e) => e.user.id == receiverId ? e = updatedContact : e)
            .toList();

        emit(
          UserChatHistoryFetchSuccess(
            userChatHistory: history.copyWith(chatContacts: newContacts),
          ),
        );
      }
    }
  }
}
