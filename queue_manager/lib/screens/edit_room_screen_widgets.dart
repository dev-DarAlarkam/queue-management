
import 'package:flutter/material.dart';
import 'package:queue_manager/models/room.dart';
import 'package:queue_manager/screens/edit_rooms_screen.dart';
import 'package:queue_manager/services/queue_service.dart';
import 'package:queue_manager/services/room_service.dart';

class RoomListTile extends StatelessWidget {
  const RoomListTile({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCurrentStudent = room.currentTicketNumber != null;

    return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(room.index.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Text(room.isClosed ? 'مغلق' : 'مفتوح'),
                          if (room.supervisorName != null &&
                              room.supervisorName!.trim().isNotEmpty)
                            Text(' • المشرف: ${room.supervisorName}'),
                        ],
                      ),
                      Text(
                        !hasCurrentStudent
                            ? 'لا يوجد طالب في الغرفة'
                            : 'الطالب الحالي: ${room.currentTicketNumber}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'فتح/إغلاق الغرفة',
                      icon: Icon(
                        room.isClosed ? Icons.lock_open : Icons.lock,
                        color: room.isClosed ? Colors.red : Colors.green,
                      ),
                      onPressed: () =>
                          RoomService.instance.toggleClosed(room),
                    ),
                    IconButton(
                      tooltip: 'تعيين التالي من الطابور',
                      icon: const Icon(Icons.person_add),
                      onPressed: room.isClosed
                          ? null
                          : () => QueueService.instance
                              .assignNextToRoom(room.id),
                    ),
                    IconButton(
                      tooltip: 'تمت خدمته',
                      icon: const Icon(Icons.done),
                      onPressed: !hasCurrentStudent
                          ? null
                          : () => QueueService.instance
                              .markCurrentServed(room.id),
                    ),
                    IconButton(
                      tooltip: 'تعديل بيانات الغرفة',
                      icon: const Icon(Icons.edit),
                      onPressed: () => EditRoomsScreen().showEditDialog(
                        context,
                        room: room,
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف الغرفة'),
                                content: Text(
                                  'هل أنت متأكد أنك تريد حذف "${room.displayName}"؟',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('إلغاء'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (confirmed) {
                          await RoomService.instance.deleteRoom(room.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}