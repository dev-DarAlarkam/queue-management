import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room.dart';

class RoomService {
  RoomService._();

  static final RoomService instance = RoomService._();

  final CollectionReference<Map<String, dynamic>> _roomsRef =
      FirebaseFirestore.instance.collection('rooms');

  Stream<List<Room>> watchRooms() {
    return _roomsRef.orderBy('index').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Room.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createRoom({
    required int index,
    required String displayName,
    String? supervisorName,
  }) async {
    await _roomsRef.add({
      'index': index,
      'displayName': displayName,
      'isClosed': false,
      'supervisorName': supervisorName,
      'currentTicketId': null,
      'currentTicketNumber': null,
    });
  }

  Future<void> updateRoom(Room room) async {
    await _roomsRef.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String id) async {
    await _roomsRef.doc(id).delete();
  }

  Future<void> toggleClosed(Room room) async {
    await _roomsRef.doc(room.id).update({'isClosed': !room.isClosed});
  }
}

