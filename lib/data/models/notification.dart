class Notification {
  final int id;
  final String title;
  final String message;
  final String? image;
  final String sendTo;
  final int isCustom;
  final int sessionYearId;
  final int schoolId;
  final String createdAt;
  final String updatedAt;
  final String type;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    this.image,
    required this.sendTo,
    required this.isCustom,
    required this.sessionYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      image: json['image'],
      sendTo: json['send_to'] ?? '',
      isCustom: json['is_custom'] ?? 0,
      sessionYearId: json['session_year_id'] ?? 0,
      schoolId: json['school_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'image': image,
      'send_to': sendTo,
      'is_custom': isCustom,
      'session_year_id': sessionYearId,
      'school_id': schoolId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'type': type,
    };
  }

  // Helper method to get DateTime from the string
  DateTime get createdDateTime {
    try {
      // Parse the date string format "10-11-2025 14:15"
      final parts = createdAt.split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');

        if (dateParts.length == 3 && timeParts.length == 2) {
          return DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[0]), // day
            int.parse(timeParts[0]), // hour
            int.parse(timeParts[1]), // minute
          );
        }
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
}
