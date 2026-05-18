class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.date,
    this.read = false,
    this.titre,
    this.redirectTo,
    this.readAt,
  });

  final int id;
  final String message;
  final String type; // CONGE | PAIE | PRESENCE | INFO | DOCUMENT | EVENT
  final DateTime date;
  final bool read;
  final String? titre;
  final String? redirectTo; // route Flutter à ouvrir au tap
  final DateTime? readAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:         (json['id'] as num?)?.toInt() ?? 0,
      message:    json['message']    as String? ?? '',
      type:       json['type']       as String? ?? 'INFO',
      date:       DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      read:       json['read']       as bool?   ?? false,
      titre:      json['titre']      as String?,
      redirectTo: json['redirectTo'] as String?,
      readAt:     json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }

  AppNotification copyWith({bool? read, DateTime? readAt}) => AppNotification(
        id: id, message: message, type: type, date: date,
        titre: titre, redirectTo: redirectTo,
        read: read ?? this.read,
        readAt: readAt ?? this.readAt,
      );
}
