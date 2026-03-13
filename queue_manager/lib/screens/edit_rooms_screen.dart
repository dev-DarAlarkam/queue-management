import 'package:flutter/material.dart';
import 'package:queue_manager/screens/edit_room_screen_widgets.dart';

import '../models/room.dart';
import '../models/ticket.dart';
import '../services/queue_service.dart';
import '../services/room_service.dart';

class EditRoomsScreen extends StatelessWidget {
  const EditRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<List<Room>>(
        stream: RoomService.instance.watchRooms(),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (roomSnapshot.hasError) {
            return Center(child: Text('Error: ${roomSnapshot.error}'));
          }
      
          final rooms = roomSnapshot.data ?? [];
      
          return StreamBuilder<List<Ticket>>(
            stream: QueueService.instance.watchWaitingTickets(),
            builder: (context, ticketSnapshot) {
              if (ticketSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (ticketSnapshot.hasError) {
                return Center(child: Text('Error: ${ticketSnapshot.error}'));
              }
      
              final waitingTickets = ticketSnapshot.data ?? [];
      
              return StreamBuilder<int>(
                stream: QueueService.instance.watchLastNumberIssued(),
                builder: (context, lastNumberSnapshot) {
                  final lastIssued = lastNumberSnapshot.data ?? 0;
      
                  return Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ____________________ Global queue section _____________________________
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_outlined,
                                  size: 18,
                                ),
                                onPressed: Navigator.of(context).pop
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    'الطابور العام',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'آخر رقم مُصدر: $lastIssued',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () => _showEditLastNumberDialog(
                                      context,
                                      currentValue: lastIssued,
                                    ),
                                    icon: const Icon(Icons.settings),
                                    label: const Text('تعيين آخر رقم'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        QueueService.instance.issueNewTicket(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('إصدار رقم'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      const SizedBox(height: 8),
                      if (waitingTickets.isEmpty)
                        Text(
                          'لا يوجد طلاب في الانتظار.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildGlobalQueue(context, waitingTickets),
                          ),
                        ),
                      const SizedBox(height: 16),
      // ____________________ Room list section _____________________________
                      Expanded(
                        child: ListView.separated(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomListTile(room: room);
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                        ),
                      ),
                    ],
                      ),
                    ),
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: () => showEditDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة غرفة'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditLastNumberDialog(
    BuildContext context, {
    required int currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعيين آخر رقم مُصدر'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'آخر رقم مُصدر',
                helperText:
                    'الرقم التالي سيكون هذا الرقم + ١.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null) return 'يجب أن يكون رقماً';
                if (parsed < 0) return 'يجب أن يكون أكبر أو يساوي صفر';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final value = int.parse(controller.text.trim());
                await QueueService.instance.setLastNumberIssued(value);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
  
  List<Widget> _buildGlobalQueue(BuildContext context, List<Ticket> waitingTickets) {
    return waitingTickets.map((t) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.number.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints.tightFor(
                      width: 24, height: 24),
              icon: const Icon(
                Icons.first_page,
                size: 18,
              ),
              tooltip: 'إرسال إلى مقدمة الطابور',
              onPressed: () => QueueService.instance
                  .moveToFrontOfLine(t),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints.tightFor(
                      width: 24, height: 24),
              icon: const Icon(
                Icons.person_remove,
                size: 18,
              ),
              tooltip: 'حذف من الطابور',
              onPressed: () => QueueService.instance
                  .removeFromLine(t),
            )
          ],
        ),
      ),
    )
    .toList();
  }

  Future<void> showEditDialog(
    BuildContext context, {
    Room? room,
  }) async {
    final indexController =
        TextEditingController(text: room?.index.toString() ?? '');
    final nameController =
        TextEditingController(text: room?.displayName ?? '');
    final supervisorController =
        TextEditingController(text: room?.supervisorName ?? '');

    final formKey = GlobalKey<FormState>();

    final isEditing = room != null;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'تعديل الغرفة' : 'إضافة غرفة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: indexController,
                    decoration: const InputDecoration(
                      labelText: 'الترتيب',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الترتيب مطلوب';
                      }
                      if (int.tryParse(value) == null) {
                        return 'الترتيب يجب أن يكون رقماً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العرض',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'اسم العرض مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: supervisorController,
                    decoration: const InputDecoration(
                      labelText: 'المشرف (اختياري)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final index = int.parse(indexController.text.trim());
                final name = nameController.text.trim();
                final supervisor = supervisorController.text.trim().isEmpty
                    ? null
                    : supervisorController.text.trim();

                if (isEditing) {
                  final updated = room.copyWith(
                    index: index,
                    displayName: name,
                    supervisorName: supervisor,
                  );
                  await RoomService.instance.updateRoom(updated);
                } else {
                  await RoomService.instance.createRoom(
                    index: index,
                    displayName: name,
                    supervisorName: supervisor,
                  );
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? 'حفظ' : 'إنشاء'),
            ),
          ],
        );
      },
    );
  }
}



