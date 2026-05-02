class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.date,
    this.read = false,
    this.titre,
  });

  final int id;
  final String message;
  final String type; // 'conge' | 'paie' | 'event' | 'document' | 'formation'
  final DateTime date;
  final bool read;
  final String? titre;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:      (json['id'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      type:    json['type']    as String? ?? 'info',
      date:    DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      read:    json['read']    as bool? ?? false,
      titre:   json['titre']   as String?,
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id, message: message, type: type, date: date,
        titre: titre, read: read ?? this.read,
      );
}
