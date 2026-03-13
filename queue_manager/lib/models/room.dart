class Room {
  final String id;
  final int index;
  final String displayName;
  final bool isClosed;
  final String? supervisorName;
  final String? currentTicketId;
  final int? currentTicketNumber;

  const Room({
    required this.id,
    required this.index,
    required this.displayName,
    required this.isClosed,
    this.supervisorName,
    this.currentTicketId,
    this.currentTicketNumber,
  });

  Room copyWith({
    String? id,
    int? index,
    String? displayName,
    bool? isClosed,
    String? supervisorName,
    String? currentTicketId,
    int? currentTicketNumber,
  }) {
    return Room(
      id: id ?? this.id,
      index: index ?? this.index,
      displayName: displayName ?? this.displayName,
      isClosed: isClosed ?? this.isClosed,
      supervisorName: supervisorName ?? this.supervisorName,
      currentTicketId: currentTicketId ?? this.currentTicketId,
      currentTicketNumber: currentTicketNumber ?? this.currentTicketNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'displayName': displayName,
      'isClosed': isClosed,
      'supervisorName': supervisorName,
      'currentTicketId': currentTicketId,
      'currentTicketNumber': currentTicketNumber,
    };
  }

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    return Room(
      id: id,
      index: (map['index'] ?? 0) as int,
      displayName: (map['displayName'] ?? '') as String,
      isClosed: (map['isClosed'] ?? false) as bool,
      supervisorName:
          map['supervisorName'] != null ? map['supervisorName'] as String : null,
      currentTicketId:
          map['currentTicketId'] != null ? map['currentTicketId'] as String : null,
      currentTicketNumber: map['currentTicketNumber'] as int?,
    );
  }
}

