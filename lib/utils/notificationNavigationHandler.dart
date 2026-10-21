import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/assignmentsCubit.dart';
import 'package:eschool/cubits/examTabSelectionCubit.dart';
import 'package:eschool/cubits/notificationsCubit.dart';
import 'package:eschool/cubits/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/cubits/studentSubjectsCubit.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/data/repositories/parentRepository.dart';
import 'package:eschool/data/repositories/subjectRepository.dart';
import 'package:eschool/ui/screens/chat/chatScreen.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Handles all notification navigation logic
/// This class is responsible for routing users to appropriate screens
/// based on notification types and payloads
class NotificationNavigationHandler {
  /// Main entry point for handling notification navigation
  /// Routes to appropriate handler based on notification type
  static Future<void> handleNotificationNavigation(
    String? type,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Wait for Get navigation to be ready
      if (Get.context == null) {
        // Wait for navigation to initialize with exponential backoff
        int attempts = 0;
        while (Get.context == null && attempts < 10) {
          await Future.delayed(Duration(milliseconds: 100 * (attempts + 1)));
          attempts++;
        }

        // If still not ready after waiting, log and return
        if (Get.context == null) {
          if (kDebugMode) {
            print(
                'Navigation not ready after waiting. Skipping notification navigation.');
          }
          return;
        }
      }

      if (data == null) {
        await _handleFallbackNotification({});
        return;
      }

      final safeType = type ?? "";

      if (kDebugMode) {
        print('Handling notification type: $safeType with data: $data');
      }

      switch (safeType.toLowerCase()) {
        case 'assignment':
          await _handleAssignmentNotification(data);
          break;

        case 'message':
          await _handleMessageNotification(data);
          break;

        case 'payment':
          await _handlePaymentNotification(data);
          break;

        case 'Notification':
        case 'general':
          await _handleFallbackNotification(data);
          break;

        case 'lesson':
          await _handleLessonNotification(data);
          break;

        case 'topic':
          await _handleTopicNotification(data);
          break;

        case 'exam':
          await _handleExamNotification(data);
          break;

        case 'exam result':
        case 'result':
          await _handleExamResultNotification(data);
          break;

        case 'attendance':
          await _handleAttendanceNotification(data);
          break;

        case 'student_leave':
        case 'student leave':
          await _handleStudentLeaveNotification(data);
          break;

        case 'class section':
        case 'announcement':
          await _handleClassSectionNotification(data);
          break;

        case 'diary':
          await _handleDiaryNotification(data);
          break;

        case 'transportation':
          await _handleTransportationNotification(data);
          break;

        case 'fees':
          await _handleFeesNotification(data);
          break;

        default:
          await _handleFallbackNotification(data);
          break;
      }
    } catch (e, st) {
      print("this is the ${e}");
      print("This is the ${st}");
      await _handleFallbackNotification(data ?? {});
    }
  }

  /// Handles assignment notification navigation
  static Future<void> _handleAssignmentNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      final String assignmentIdRaw =
          (data['assignment_id'] ?? data['assignmentId'] ?? '').toString();
      final String classSubjectIdRaw =
          (data['class_subject_id'] ?? data['classSubjectId'] ?? '0')
              .toString();

      // Extract assignment_status_update from payload (0 = pending, 1 = submitted)
      // Handle both 'assignment_status_update' and 'assigment_status_update' (typo in backend)
      // Default to 0 (pending) if not provided for backward compatibility
      final String assignmentStatusRaw = (data['assignment_status_update'] ??
              data['assigment_status_update'] ??
              '0')
          .toString();
      final int assignmentStatus = int.tryParse(assignmentStatusRaw) ?? 0;

      // Validate assignment_status_update value (must be 0 or 1)
      final int isSubmitted = (assignmentStatus == 0 || assignmentStatus == 1)
          ? assignmentStatus
          : 0;

      if (kDebugMode) {
        print(
            'Assignment notification - ID: $assignmentIdRaw, Status: $isSubmitted (0=pending, 1=submitted)');
      }

      if (assignmentIdRaw.isEmpty || assignmentIdRaw == 'null') {
        return;
      }

      final int assignmentId = int.tryParse(assignmentIdRaw) ?? 0;
      final int? classSubjectId = int.tryParse(classSubjectIdRaw);

      if (assignmentId <= 0) {
        return;
      }

      final context = Get.context;
      if (context == null) {
        return;
      }

      final assignmentsCubit = context.read<AssignmentsCubit>();

      assignmentsCubit.fetchAssignments(
        isSubmitted: isSubmitted,
        childId: AuthRepository.getStudentDetails().id ?? 0,
        useParentApi: false,
        assignmentId: assignmentId,
        classSubjectId: (classSubjectId == 0) ? null : classSubjectId,
      );

      final resultState = await assignmentsCubit.stream
          .firstWhere(
            (state) =>
                state is AssignmentsFetchSuccess ||
                state is AssignmentsFetchFailure,
            orElse: () => assignmentsCubit.state,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => assignmentsCubit.state,
          );

      if (resultState is! AssignmentsFetchSuccess) {
        return;
      }

      final assignments = assignmentsCubit.getAssignedAssignments();

      if (assignments.isEmpty) {
        final allAssignments = resultState.assignments;

        if (allAssignments.isNotEmpty) {
          final targetAssignment = allAssignments.firstWhere(
            (a) => a.id == assignmentId,
            orElse: () => allAssignments.first,
          );

          Get.toNamed(Routes.assignment, arguments: targetAssignment);
          return;
        }

        return;
      }

      final targetAssignment = assignments.first;
      Get.toNamed(Routes.assignment, arguments: targetAssignment);
    } catch (e) {
      // Error handling - silent failure
    }
  }

  /// Handles message/chat notification navigation
  static Future<void> _handleMessageNotification(
    Map<String, dynamic> data,
  ) async {
    final String? receiverIdStr = data['receiver_id'] ??
        data['receiverId'] ??
        data['sender_id'] ??
        data['senderId'];
    final String? teacherName = data['teacher_name'] ??
        data['teacherName'] ??
        data['sender_name'] ??
        data['senderName'];
    final String? teacherImage = data['teacher_image'] ??
        data['teacherImage'] ??
        data['sender_image'] ??
        data['senderImage'];
    final String? subjectName =
        data['subject_name'] ?? data['subjectName'] ?? data['subject'];

    if (receiverIdStr != null && teacherName != null) {
      try {
        final int receiverId = int.parse(receiverIdStr);
        final String image = teacherImage ?? '';
        final String appbarSubtitle = subjectName ?? '';

        if (Get.currentRoute != Routes.chat) {
          final arguments = ChatScreen.buildArguments(
            receiverId: receiverId,
            image: image,
            teacherName: teacherName,
            appbarSubtitle: appbarSubtitle,
          );
          arguments['fromNotification'] = true;

          Get.toNamed(Routes.chat, arguments: arguments);
        }
      } catch (e) {
        _navigateToChatContacts();
      }
    } else {
      _navigateToChatContacts();
    }
  }

  /// Handles payment notification navigation
  static Future<void> _handlePaymentNotification(
    Map<String, dynamic> data,
  ) async {
    if (Get.currentRoute != Routes.transactions) {
      Get.toNamed(Routes.transactions);
    }
  }

  /// Handles lesson notification navigation
  static Future<void> _handleLessonNotification(
    Map<String, dynamic> data,
  ) async {
    final String? subjectIdStr =
        data['subject_id']?.toString() ?? data['subjectId']?.toString();
    final String? subjectName =
        data['subject_name'] ?? data['subjectName'] ?? data['subject'];

    final String? classSubjectIdRaw =
        data['class_subject_id'] ?? data['classSubjectId'];
    final String? classSubjectIdStr = (classSubjectIdRaw != null &&
            classSubjectIdRaw.toString().isNotEmpty &&
            classSubjectIdRaw.toString() != '')
        ? classSubjectIdRaw.toString()
        : null;

    // Extract child_id from notification payload for parent users
    final String? childIdStr =
        data['child_id']?.toString() ?? data['childId']?.toString();
    final int? childIdFromNotification =
        childIdStr != null ? (int.tryParse(childIdStr) ?? 0) : null;

    // Determine the correct child ID
    int? childId;
    if (!AuthRepository.getIsStudentLogIn()) {
      // For parent, use child_id from notification if available
      if (childIdFromNotification != null && childIdFromNotification > 0) {
        childId = childIdFromNotification;
      } else {
        // Fallback to first child
        childId =
            AuthRepository.getParentDetails().children?.firstOrNull?.id ?? 0;
      }
    }

    if (subjectIdStr != null && subjectIdStr.isNotEmpty) {
      try {
        Subject? targetSubject = await _findSubjectFromNotificationData(
          subjectIdStr: subjectIdStr,
          subjectName: subjectName,
          classSubjectIdStr: classSubjectIdStr,
          childId: childId,
        );

        if (targetSubject != null) {
          if (Get.currentRoute != Routes.subjectDetails) {
            final arguments = {
              "childId": AuthRepository.getIsStudentLogIn() ? null : childId,
              "subject": targetSubject,
              "autoNavigateToChapters": true,
            };

            Get.toNamed(Routes.subjectDetails, arguments: arguments);
          }
        } else {
          _navigateToNoticeBoard(childId: childId);
        }
      } catch (e, st) {
        print("this is the ${e}");
        print("This is the ${st}");
        _navigateToNoticeBoard(childId: childId);
      }
    } else {
      _navigateToNoticeBoard(childId: childId);
    }
  }

  /// Handles topic notification navigation - navigates to Topic Details screen
  static Future<void> _handleTopicNotification(
    Map<String, dynamic> data,
  ) async {
    final String? classSubjectIdRaw = data['class_subject_id']?.toString() ??
        data['classSubjectId']?.toString();
    final String? lessonIdRaw =
        data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    final String? topicIdRaw =
        data['topic_id']?.toString() ?? data['topicId']?.toString();

    // Extract files field to determine which tab to show
    // file_upload -> Files tab, video_upload -> Videos tab, other_link -> External Link tab
    final String? filesType = data['files']?.toString();

    // Extract child_id from notification payload for parent users
    final String? childIdStr =
        data['child_id']?.toString() ?? data['childId']?.toString();
    final int? childIdFromNotification =
        childIdStr != null ? (int.tryParse(childIdStr) ?? 0) : null;

    // Determine the correct child ID
    int? childId;
    if (!AuthRepository.getIsStudentLogIn()) {
      // For parent, use child_id from notification if available
      if (childIdFromNotification != null && childIdFromNotification > 0) {
        childId = childIdFromNotification;
      } else {
        // Fallback to first child
        childId =
            AuthRepository.getParentDetails().children?.firstOrNull?.id ?? 0;
      }
    }

    if (kDebugMode) {
      print(
          'Topic notification - class_subject_id: $classSubjectIdRaw, lesson_id: $lessonIdRaw, topic_id: $topicIdRaw, files: $filesType, child_id: $childId');
    }

    // Validate required parameters
    if (classSubjectIdRaw == null || classSubjectIdRaw.isEmpty) {
      if (kDebugMode) {
        print('Topic notification missing class_subject_id, falling back');
      }
      _navigateToNoticeBoard(childId: childId);
      return;
    }

    final int classSubjectId = int.tryParse(classSubjectIdRaw) ?? 0;
    final int lessonId = int.tryParse(lessonIdRaw ?? '0') ?? 0;
    final int topicId = int.tryParse(topicIdRaw ?? '0') ?? 0;

    if (classSubjectId <= 0) {
      if (kDebugMode) {
        print(
            'Topic notification has invalid class_subject_id: $classSubjectId');
      }
      _navigateToNoticeBoard(childId: childId);
      return;
    }

    try {
      final subjectRepository = SubjectRepository();
      final bool useParentApi = !AuthRepository.getIsStudentLogIn();

      // Fetch lessons for the subject
      final lessons = await subjectRepository.getLessons(
        classSubjectId: classSubjectId,
        childId: childId ?? 0,
        useParentApi: useParentApi,
      );

      if (lessons.isEmpty) {
        if (kDebugMode) {
          print('No lessons found for class_subject_id: $classSubjectId');
        }
        _navigateToNoticeBoard(childId: childId);
        return;
      }

      // Find the specific lesson by lesson_id, or use the first one
      final targetLesson = lessonId > 0
          ? lessons.firstWhere(
              (lesson) => lesson.id == lessonId,
              orElse: () => lessons.first,
            )
          : lessons.first;

      // Find the specific topic by topic_id within the lesson
      if (topicId > 0 && targetLesson.topics.isNotEmpty) {
        final targetTopic = targetLesson.topics.firstWhere(
          (topic) => topic.id == topicId,
          orElse: () => targetLesson.topics.first,
        );

        // Determine which tab to show based on files field
        // file_upload -> files, video_upload -> videos, other_link -> otherLink
        // Default to files if null, empty, or unrecognized
        String initialTab;
        switch (filesType?.toLowerCase()) {
          case 'video_upload':
            initialTab = videosKey;
            break;
          case 'other_link':
            initialTab = otherLinkKey;
            break;
          case 'file_upload':
          default:
            initialTab = filesKey;
            break;
        }

        if (kDebugMode) {
          print(
              'Navigating to topic details for topic: ${targetTopic.name}, initialTab: $initialTab');
        }

        // Navigate to Topic Details screen
        if (Get.currentRoute != Routes.topicDetails) {
          Get.toNamed(
            Routes.topicDetails,
            arguments: {
              'topic': targetTopic,
              'childId': childId,
              'initialTab': initialTab,
            },
          );
        }
      } else {
        // Fallback to Chapter Details if no topic_id or no topics in lesson
        if (kDebugMode) {
          print(
              'No topic_id or topics found, falling back to chapter details for lesson: ${targetLesson.name}');
        }

        if (Get.currentRoute != Routes.chapterDetails) {
          Get.toNamed(
            Routes.chapterDetails,
            arguments: {
              'lesson': targetLesson,
              'childId': childId,
            },
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Error handling topic notification: $e');
        print('Stack trace: $st');
      }
      _navigateToNoticeBoard(childId: childId);
    }
  }

  /// Handles exam notification navigation
  static Future<void> _handleExamNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      final String examType =
          (data['exam_type'] ?? 'offline').toString().toLowerCase();

      List<Subject>? subjects;
      int? childId;

      if (AuthRepository.getIsStudentLogIn()) {
        final context = Get.context;
        if (context != null) {
          try {
            final cubit = context.read<StudentSubjectsAndSlidersCubit>();
            subjects = cubit.getSubjectsForAssignmentContainer();
          } catch (e) {
            // Error getting student subjects
          }
        }
      } else {
        final parentDetails = AuthRepository.getParentDetails();
        childId = parentDetails.children?.firstOrNull?.id;

        final context = Get.context;
        if (context != null) {
          try {
            final cubit = context.read<ChildSubjectsCubit>();
            subjects = cubit.getSubjectsForAssignmentContainer();
          } catch (e) {
            // Error getting child subjects
          }
        }
      }

      final context = Get.context;
      if (context != null) {
        try {
          final examTabCubit = context.read<ExamTabSelectionCubit>();
          final String targetTab =
              examType == 'online' ? onlineKey : offlineKey;
          examTabCubit.changeExamFilterTabTitle(targetTab);
          examTabCubit.changeExamFilterBySubjectId(0);
        } catch (e) {
          // Error setting exam tab
        }
      }

      if (Get.currentRoute != Routes.exam) {
        Get.toNamed(
          Routes.exam,
          arguments: {
            'childId': childId,
            'subjects': subjects,
          },
        );
      }
    } catch (e) {
      _navigateToNoticeBoard();
    }
  }

  /// Handles exam result notification navigation
  static Future<void> _handleExamResultNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      final String resultIdRaw = (data['result_id'] ??
              data['exam_id'] ??
              data['resultId'] ??
              data['examId'] ??
              '')
          .toString();

      if (resultIdRaw.isNotEmpty) {
        final int resultId = int.tryParse(resultIdRaw) ?? 0;

        Get.toNamed(
          Routes.result,
          arguments: {'resultId': resultId, 'fromNotification': true},
        );
      } else {
        Get.toNamed(Routes.result);
      }
    } catch (e) {
      Get.toNamed(Routes.result);
    }
  }

  /// Handles attendance notification navigation
  static Future<void> _handleAttendanceNotification(
    Map<String, dynamic> data,
  ) async {
    if (Get.currentRoute != Routes.childAttendance) {
      final String childIdStr =
          (data['child_id'] ?? data['childId'] ?? '0').toString();
      final int childId = int.tryParse(childIdStr) ?? 0;

      Get.toNamed(
        Routes.childAttendance,
        arguments: {
          'childId': childId,
        },
      );
    }
  }

  /// Handles student leave notification navigation
  ///
  /// The leaves screen reads its child id straight from `Get.arguments` as an
  /// int, so the child has to be resolved before navigating. When no child can
  /// be resolved the notification list is opened instead of throwing.
  static Future<void> _handleStudentLeaveNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      // Extract child_id from notification data
      final String childIdStr = (data['child_id'] ??
              data['childId'] ??
              data['student_id'] ??
              data['studentId'] ??
              '0')
          .toString();

      final int childIdFromNotification = int.tryParse(childIdStr) ?? 0;

      // Determine the target child based on user type
      int targetChildId;

      if (AuthRepository.getIsStudentLogIn()) {
        // For student login, use their own ID
        targetChildId = AuthRepository.getStudentDetails().id ?? 0;
      } else {
        // For parent login, open the child the leave belongs to
        final children = AuthRepository.getParentDetails().children;

        if (children == null || children.isEmpty) {
          if (kDebugMode) {
            print('No children found for parent');
          }
          await _handleFallbackNotification(data);
          return;
        }

        // Fall back to the first child when the payload carries no child_id,
        // or names a child that does not belong to this parent
        final targetChild = childIdFromNotification > 0
            ? children.firstWhere(
                (child) => child.id == childIdFromNotification,
                orElse: () => children.first,
              )
            : children.first;

        targetChildId = targetChild.id ?? 0;
      }

      if (kDebugMode) {
        print('Student leave notification - childId: $targetChildId');
      }

      if (targetChildId <= 0) {
        await _handleFallbackNotification(data);
        return;
      }

      if (Get.currentRoute != Routes.studentLeaves) {
        Get.toNamed(Routes.studentLeaves, arguments: targetChildId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling student leave notification: $e');
      }
      await _handleFallbackNotification(data);
    }
  }

  /// Handles class section notification navigation
  static Future<void> _handleClassSectionNotification(
    Map<String, dynamic> data,
  ) async {
    final String? subjectIdStr = data['subject_id'] ??
        data['subjectId'] ??
        data['class_subject_id'] ??
        data['classSubjectId'];
    final String? subjectName =
        data['subject_name'] ?? data['subjectName'] ?? data['subject'];
    final String? classSubjectIdStr =
        data['class_subject_id'] ?? data['classSubjectId'];

    // Extract child_id from notification payload for parent users
    final String? childIdStr =
        data['child_id']?.toString() ?? data['childId']?.toString();
    final int? childIdFromNotification =
        childIdStr != null ? (int.tryParse(childIdStr) ?? 0) : null;

    // Determine the correct child ID
    int? childId;
    if (!AuthRepository.getIsStudentLogIn()) {
      // For parent, use child_id from notification if available
      if (childIdFromNotification != null && childIdFromNotification > 0) {
        childId = childIdFromNotification;
      } else {
        // Fallback to first child
        childId =
            AuthRepository.getParentDetails().children?.firstOrNull?.id ?? 0;
      }
    }

    if (subjectIdStr != null ||
        subjectName != null ||
        classSubjectIdStr != null) {
      try {
        Subject? targetSubject = await _findSubjectFromNotificationData(
          subjectIdStr: subjectIdStr,
          subjectName: subjectName,
          classSubjectIdStr: classSubjectIdStr,
          childId: childId,
        );

        if (targetSubject != null) {
          if (Get.currentRoute != Routes.subjectDetails) {
            Get.toNamed(
              Routes.subjectDetails,
              arguments: {
                "childId": AuthRepository.getIsStudentLogIn() ? null : childId,
                "subject": targetSubject,
                "autoNavigateToAnnouncement": true,
              },
            );
          }
        } else {
          _navigateToNoticeBoard(childId: childId);
        }
      } catch (e) {
        _navigateToNoticeBoard(childId: childId);
      }
    } else {
      _navigateToNoticeBoard(childId: childId);
    }
  }

  /// Handles diary notification navigation
  static Future<void> _handleDiaryNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      // Extract student_id from notification data
      final String studentIdStr =
          (data['student_id'] ?? data['studentId'] ?? data['id'] ?? '0')
              .toString();

      final int studentId = int.tryParse(studentIdStr) ?? 0;

      // Determine the correct student ID and child ID based on user type
      int targetStudentId;
      int targetId;

      if (AuthRepository.getIsStudentLogIn()) {
        // For student login, use their own ID
        targetStudentId = AuthRepository.getStudentDetails().id ?? 0;
        targetId = targetStudentId;
      } else {
        // For parent login, match the student_id from notification against
        // the child's user_id or id. If not found, fall back to first child
        final children = AuthRepository.getParentDetails().children;
        final child = (studentId > 0
                ? children?.firstWhereOrNull(
                    (child) =>
                        child.userId == studentId || child.id == studentId,
                  )
                : null) ??
            children?.firstOrNull;
        targetStudentId = child?.userId ?? 0;
        targetId = child?.id ?? 0;
      }

      // Only navigate if we have a valid student ID
      if (targetStudentId > 0 &&
          Get.currentRoute != Routes.studentDiaryScreen) {
        Get.toNamed(
          Routes.studentDiaryScreen,
          arguments: {
            'studentId': targetStudentId,
            'id': targetId,
          },
        );
      }
    } catch (e) {
      // If anything goes wrong, silently fail or navigate to fallback
      if (kDebugMode) {
        print('Error handling diary notification: $e');
      }
    }
  }

  /// Handles transportation notification navigation
  static Future<void> _handleTransportationNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      // Extract user_id from notification data
      final String userIdStr = (data['user_id'] ??
              data['userId'] ??
              data['student_id'] ??
              data['studentId'] ??
              '0')
          .toString();

      final int userId = int.tryParse(userIdStr) ?? 0;

      // Determine the correct user ID based on user type
      int targetUserId;

      if (AuthRepository.getIsStudentLogIn()) {
        // For student login, use their own ID
        targetUserId = AuthRepository.getStudentDetails().id ?? 0;
      } else {
        // For parent login, use the user_id from notification
        // If not provided, fall back to first child
        if (userId > 0) {
          targetUserId = userId;
        } else {
          final firstChild =
              AuthRepository.getParentDetails().children?.firstOrNull;
          targetUserId = firstChild?.id ?? 0;
        }
      }

      // Only navigate if we have a valid user ID
      if (targetUserId > 0 &&
          Get.currentRoute != Routes.transportEnrollHomeScreen) {
        Get.toNamed(
          Routes.transportEnrollHomeScreen,
          arguments: targetUserId,
        );
      } else if (kDebugMode) {
        print('Invalid user ID for transportation notification: $targetUserId');
      }
    } catch (e) {
      // If anything goes wrong, log error
      if (kDebugMode) {
        print('Error handling transportation notification: $e');
      }
    }
  }

  /// Handles fees notification navigation
  static Future<void> _handleFeesNotification(
    Map<String, dynamic> data,
  ) async {
    try {
      // Extract child_id from notification data
      final String childIdStr = (data['child_id'] ??
              data['childId'] ??
              data['student_id'] ??
              data['studentId'] ??
              '0')
          .toString();

      final int childId = int.tryParse(childIdStr) ?? 0;

      if (kDebugMode) {
        print('Fees notification - child_id: $childId');
      }

      // Determine the target child based on user type
      Student? targetChild;

      if (AuthRepository.getIsStudentLogIn()) {
        // For student login, use their own details
        final studentDetails = AuthRepository.getStudentDetails();

        if (studentDetails.id == null || studentDetails.id! <= 0) {
          if (kDebugMode) {
            print('Invalid student ID for fees notification');
          }
          return;
        }

        // Convert StudentDetails to Student object
        targetChild = studentDetails;
      } else {
        // For parent login, fetch the specific child from children list
        final parentDetails = AuthRepository.getParentDetails();
        final children = parentDetails.children;

        if (children == null || children.isEmpty) {
          if (kDebugMode) {
            print('No children found for parent');
          }
          return;
        }

        // Find the child matching the child_id from notification
        if (childId > 0) {
          targetChild = children.firstWhere(
            (child) => child.id == childId,
            orElse: () => children.first,
          );
        } else {
          // Fallback to first child if child_id not provided
          targetChild = children.first;
        }

        if (targetChild.id == null || targetChild.id! <= 0) {
          if (kDebugMode) {
            print('Invalid child ID found: ${targetChild.id}');
          }
          return;
        }
      }

      // Navigate to ChildFeesScreen with the Student object
      if (Get.currentRoute != Routes.childFees) {
        if (kDebugMode) {
          print('Navigating to fees screen for child: ${targetChild.id}');
        }

        Get.toNamed(
          Routes.childFees,
          arguments: targetChild,
        );
      }
    } catch (e) {
      // If anything goes wrong, log error
      if (kDebugMode) {
        print('Error handling fees notification: $e');
      }
    }
  }

  /// Fallback notification handler - navigates to general notifications screen
  static Future<void> _handleFallbackNotification(
    Map<String, dynamic> data,
  ) async {
    if (Get.currentRoute == Routes.notifications) {
      final currentContext = Get.context;
      if (currentContext != null) {
        try {
          final notificationsCubit = currentContext.read<NotificationsCubit>();
          notificationsCubit.fetchNotifications();
        } catch (e) {
          // Error refreshing notifications
        }
      }
      return;
    }

    Get.toNamed(Routes.notifications);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Finds subject from notification data using multiple fallback strategies
  /// Tries: class_subject_id -> subject_id -> subject_name
  /// For parent users, childId parameter can be provided to fetch subjects for specific child
  static Future<Subject?> _findSubjectFromNotificationData({
    String? subjectIdStr,
    String? subjectName,
    String? classSubjectIdStr,
    int? childId,
  }) async {
    try {
      List<Subject> subjects = [];

      if (AuthRepository.getIsStudentLogIn()) {
        final context = Get.context;
        if (context != null) {
          try {
            final cubit = context.read<StudentSubjectsAndSlidersCubit>();
            subjects = cubit.getSubjects();
          } catch (e) {
            // Error getting student subjects
          }
        }
      } else {
        // For parent users, fetch subjects directly from repository for the specific child
        if (childId != null && childId > 0) {
          try {
            final parentRepository = ParentRepository();

            // Fetch subjects for the specific child from notification
            final result =
                await parentRepository.fetchChildSubjects(childId: childId);

            // Extract subjects from result
            final List<Subject> coreSubjects = result['coreSubjects'] ?? [];
            final List<Subject> electiveSubjects =
                result['electiveSubjects'] ?? [];

            // Combine core and elective subjects
            subjects.addAll(coreSubjects.where((element) => element.id != 0));
            subjects
                .addAll(electiveSubjects.where((element) => element.id != 0));

            if (kDebugMode) {
              print('Fetched ${subjects.length} subjects for childId $childId');
            }
          } catch (e) {
            // Error getting child subjects
            if (kDebugMode) {
              print('Error fetching child subjects for childId $childId: $e');
            }
          }
        }
      }

      if (subjects.isEmpty) {
        if (kDebugMode) {
          print('No subjects found for childId: $childId');
        }
        return null;
      }

      if (classSubjectIdStr != null) {
        final int classSubjectId = int.tryParse(classSubjectIdStr) ?? 0;
        if (classSubjectId > 0) {
          final subject = subjects.firstWhere(
            (s) => s.classSubjectId == classSubjectId,
            orElse: () => Subject(),
          );
          if (subject.id != null && subject.id! > 0) {
            return subject;
          }
        }
      }

      if (subjectIdStr != null) {
        final int subjectId = int.tryParse(subjectIdStr) ?? 0;
        if (subjectId > 0) {
          final subject = subjects.firstWhere(
            (s) => s.id == subjectId,
            orElse: () => Subject(),
          );
          if (subject.id != null && subject.id! > 0) {
            return subject;
          }
        }
      }

      if (subjectName != null && subjectName.isNotEmpty) {
        final subject = subjects.firstWhere(
          (s) =>
              s.name?.toLowerCase().contains(subjectName.toLowerCase()) == true,
          orElse: () => Subject(),
        );
        if (subject.id != null && subject.id! > 0) {
          return subject;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Navigates to chat contacts screen
  static void _navigateToChatContacts() {
    if (Get.currentRoute != Routes.chatContacts) {
      Get.toNamed(Routes.chatContacts);
    }
  }

  /// Navigates to notice board screen
  static void _navigateToNoticeBoard({int? childId}) {
    if (Get.currentRoute != Routes.noticeBoard) {
      Get.toNamed(Routes.noticeBoard, arguments: childId);
    }
  }
}
