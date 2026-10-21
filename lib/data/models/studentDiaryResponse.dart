import 'package:eschool/data/models/diaryStudent.dart';

class StudentDiaryResponse {
  final int currentPage;
  final List<DiaryStudent> diaryEntries;
  final String firstPageUrl;
  final int? from;
  final int lastPage;
  final String lastPageUrl;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  StudentDiaryResponse({
    required this.currentPage,
    required this.diaryEntries,
    required this.firstPageUrl,
    this.from,
    required this.lastPage,
    required this.lastPageUrl,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  StudentDiaryResponse.fromJson(Map<String, dynamic> json)
      : currentPage = json['current_page'] as int? ?? 0,
        diaryEntries = _parseDiaryEntries(json['data']),
        firstPageUrl = json['first_page_url'] as String? ?? '',
        from = json['from'] as int?,
        lastPage = json['last_page'] as int? ?? 0,
        lastPageUrl = json['last_page_url'] as String? ?? '',
        nextPageUrl = json['next_page_url'] as String?,
        path = json['path'] as String? ?? '',
        perPage = json['per_page'] as int? ?? 0,
        prevPageUrl = json['prev_page_url'] as String?,
        to = json['to'] as int?,
        total = json['total'] as int? ?? 0;

  /// The `data` array now contains diary entries directly (each item holds a
  /// `diary` object). Older responses wrapped these inside a student object
  /// under a `diary_student` list, so we flatten that shape too for safety.
  static List<DiaryStudent> _parseDiaryEntries(dynamic data) {
    final List<DiaryStudent> entries = [];

    for (final item in (data as List? ?? [])) {
      final map = Map<String, dynamic>.from(item ?? {});

      if (map['diary'] != null) {
        // New flat format: item is a diary entry itself.
        entries.add(DiaryStudent.fromJson(map));
      } else if (map['diary_student'] is List) {
        // Legacy format: student wrapping a list of diary entries.
        for (final diaryStudent in (map['diary_student'] as List)) {
          entries.add(
            DiaryStudent.fromJson(
                Map<String, dynamic>.from(diaryStudent ?? {})),
          );
        }
      }
    }

    return entries;
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'data': diaryEntries.map((entry) => entry.toJson()).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };
}
