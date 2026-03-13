import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { waiting, assigned, skipped, served }

class Ticket {
  final String id;
  final int number;
  final TicketStatus status;
  final String? roomId;
  final DateTime createdAt;
  /// When set, this ticket is ordered by [queueOrder] in the waiting line (earlier = front).
  final DateTime? queueOrder;

  const Ticket({
    required this.id,
    required this.number,
    required this.status,
    required this.createdAt,
    this.roomId,
    this.queueOrder,
  });

  /// Effective position in the waiting line (smaller = front).
  DateTime get effectiveOrder => queueOrder ?? createdAt;

  Ticket copyWith({
    String? id,
    int? number,
    TicketStatus? status,
    String? roomId,
    DateTime? createdAt,
    DateTime? queueOrder,
  }) {
    return Ticket(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      queueOrder: queueOrder ?? this.queueOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'status': status.name,
      'roomId': roomId,
      'createdAt': createdAt.toUtc(),
      if (queueOrder != null) 'queueOrder': queueOrder!.toUtc(),
    };
  }

  factory Ticket.fromMap(String id, Map<String, dynamic> map) {
    final statusString = (map['status'] ?? 'waiting') as String;
    final status = TicketStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => TicketStatus.waiting,
    );

    final createdAt = _parseDateTime(map['createdAt']) ?? DateTime.now().toUtc();
    final queueOrder = _parseDateTime(map['queueOrder']);

    return Ticket(
      id: id,
      number: (map['number'] ?? 0) as int,
      status: status,
      roomId: map['roomId'] as String?,
      createdAt: createdAt,
      queueOrder: queueOrder,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

