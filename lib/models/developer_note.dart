class DeveloperNote {
  final int? id;
  final String content;
  final DateTime date;
  final bool isCompleted;

  DeveloperNote({
    this.id,
    required this.content,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'date': date.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory DeveloperNote.fromMap(Map<String, dynamic> map) {
    return DeveloperNote(
      id: map['id'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      isCompleted: map['is_completed'] == 1,
    );
  }

  DeveloperNote copyWith({int? id, String? content, DateTime? date, bool? isCompleted}) {
    return DeveloperNote(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}