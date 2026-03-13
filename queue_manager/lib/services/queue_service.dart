import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ticket.dart';

class QueueService {
  QueueService._();

  static final QueueService instance = QueueService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      _db.collection('tickets');

  DocumentReference<Map<String, dynamic>> get _metaRef =>
      _db.collection('meta').doc('queue');

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('rooms');

  /// Stream of all tickets, mainly for debugging or advanced UIs.
  Stream<List<Ticket>> watchAllTickets() {
    return _ticketsRef
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ticket.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Stream of waiting tickets (global line), ordered front-first (by queueOrder then createdAt).
  Stream<List<Ticket>> watchWaitingTickets() {
    return _ticketsRef
        .where('status', isEqualTo: TicketStatus.waiting.name)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Ticket.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => a.effectiveOrder.compareTo(b.effectiveOrder));
          return list;
        });
  }

  /// Stream of tickets currently assigned to a specific room.
  Stream<List<Ticket>> watchRoomAssignedTickets(String roomId) {
    return _ticketsRef
        .where('status', isEqualTo: TicketStatus.assigned.name)
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ticket.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Helper: get next number from meta doc using a transaction.
  Future<int> _getNextNumber() async {
    return _db.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_metaRef);

      int lastNumber = 0;
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['lastNumberIssued'] is int) {
          lastNumber = data['lastNumberIssued'] as int;
        }
      }

      final next = lastNumber + 1;
      transaction.set(
        _metaRef,
        {'lastNumberIssued': next},
        SetOptions(merge: true),
      );
      return next;
    });
  }

  Stream<int> watchLastNumberIssued() {
    return _metaRef.snapshots().map((snapshot) {
      final data = snapshot.data();
      final value = data != null ? data['lastNumberIssued'] : null;
      return value is int ? value : 0;
    });
  }

  Future<void> setLastNumberIssued(int value) async {
    if (value < 0) return;
    await _metaRef.set({'lastNumberIssued': value}, SetOptions(merge: true));
  }

  /// Issue a new ticket into the global waiting line.
  Future<void> issueNewTicket() async {
    final nextNumber = await _getNextNumber();
    await _ticketsRef.add({
      'number': nextNumber,
      'status': TicketStatus.waiting.name,
      'roomId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a ticket from the waiting line.
  Future<void> removeFromLine(Ticket ticket) async {
    await _ticketsRef.doc(ticket.id).update({
      'status': TicketStatus.skipped.name,
    });
  }

  /// Move a waiting ticket to the front of the line (next to be assigned).
  Future<void> moveToFrontOfLine(Ticket ticket) async {
    if (ticket.status != TicketStatus.waiting) return;

    final snapshot = await _ticketsRef
        .where('status', isEqualTo: TicketStatus.waiting.name)
        .get();
    final waiting = snapshot.docs
        .map((doc) => Ticket.fromMap(doc.id, doc.data()))
        .toList();
    waiting.sort((a, b) => a.effectiveOrder.compareTo(b.effectiveOrder));
    if (waiting.isEmpty || waiting.first.id == ticket.id) return;

    final frontOrder = waiting.first.effectiveOrder;
    final newOrder = frontOrder.subtract(const Duration(seconds: 1));
    await _ticketsRef.doc(ticket.id).update({
      'queueOrder': Timestamp.fromDate(newOrder),
    });
  }

  /// Assign the ticket at the front of the waiting line to a room.
  Future<void> assignNextToRoom(String roomId) async {
    final snapshot = await _ticketsRef
        .where('status', isEqualTo: TicketStatus.waiting.name)
        .get();
    final waiting = snapshot.docs
        .map((doc) => Ticket.fromMap(doc.id, doc.data()))
        .toList();
    waiting.sort((a, b) => a.effectiveOrder.compareTo(b.effectiveOrder));
    if (waiting.isEmpty) return;

    final first = waiting.first;
    await _ticketsRef.doc(first.id).update({
      'status': TicketStatus.assigned.name,
      'roomId': roomId,
    });
    await _roomsRef.doc(roomId).update({
      'currentTicketId': first.id,
      'currentTicketNumber': first.number,
    });
  }

  /// Mark the currently assigned ticket for the room as served.
  Future<void> markCurrentServed(String roomId) async {
    await _updateCurrentForRoom(roomId);
  }

  /// Mark the current student in the room as no-show.
  Future<void> markNoShow(String roomId) async {
    // Mark the current ticket as skipped and clear the room.
    final query = await _ticketsRef
        .where('status', isEqualTo: TicketStatus.assigned.name)
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return;
    }

    final doc = query.docs.first;
    await doc.reference.update({
      'status': TicketStatus.skipped.name,
      'roomId': null,
    });

    await _roomsRef.doc(roomId).update({
      'currentTicketId': null,
      'currentTicketNumber': null,
    });
  }

  /// Helper used for "served": mark the current ticket (by id stored on the room)
  /// as served and clear it from the room.
  Future<void> _updateCurrentForRoom(String roomId) async {
    final roomSnap = await _roomsRef.doc(roomId).get();
    final data = roomSnap.data();
    final String? ticketId =
        data != null ? data['currentTicketId'] as String? : null;

    if (ticketId == null) {
      return;
    }

    await _ticketsRef.doc(ticketId).update({
      'status': TicketStatus.served.name,
      'roomId': null,
    });
    await _roomsRef.doc(roomId).update({
      'currentTicketId': null,
      'currentTicketNumber': null,
    });
  }
}
