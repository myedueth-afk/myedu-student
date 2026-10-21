class DiaryCategory {
  DiaryCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  late final int id;
  late final String name;
  late final String type; // "positive" or "negative"
  late final DateTime createdAt;
  late final DateTime updatedAt;
  late final DateTime? deletedAt;

  DiaryCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name'] ?? "";
    type = json['type'] ?? "";
    createdAt = json['created_at'] == null
        ? DateTime.now()
        : _parseDateTime(json['created_at']);
    updatedAt = json['updated_at'] == null
        ? DateTime.now()
        : _parseDateTime(json['updated_at']);
    deletedAt =
        json['deleted_at'] == null ? null : _parseDateTime(json['deleted_at']);
  }

  static DateTime _parseDateTime(String dateString) {
    try {
      // Try to parse the date string directly first (ISO 8601 format)
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // Handle format like "26-08-2025 11:45" (dd-MM-yyyy HH:mm)
        if (dateString.contains('-') && dateString.split('-').length == 3) {
          final parts = dateString.split(' ');
          final datePart = parts[0]; // "26-08-2025"
          final timePart = parts.length > 1 ? parts[1] : "00:00"; // "11:45"

          final dateParts = datePart.split('-');
          if (dateParts.length == 3) {
            final day = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);

            final timeParts = timePart.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

            return DateTime(year, month, day, hour, minute);
          }
        }

        // Handle format like "2025-07-10 04:53 AM"
        final parts = dateString.split(' ');
        if (parts.length >= 3) {
          final datePart = parts[0]; // "2025-07-10"
          final timePart = parts[1]; // "04:53"
          final amPm = parts[2]; // "AM" or "PM"

          final timeParts = timePart.split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);

          // Convert to 24-hour format
          if (amPm.toUpperCase() == 'PM' && hour != 12) {
            hour += 12;
          } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }

          final formattedTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
          final isoString = '${datePart}T$formattedTime';

          return DateTime.parse(isoString);
        }
      } catch (e2) {
        // If all parsing fails, return current time
        return DateTime.now();
      }
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return name;
  }
}
