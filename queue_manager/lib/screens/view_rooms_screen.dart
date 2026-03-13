import 'package:flutter/material.dart';

import '../models/room.dart';
import '../models/ticket.dart';
import '../services/queue_service.dart';
import '../services/room_service.dart';
class ViewRoomsScreenWrapper extends StatelessWidget {
  const ViewRoomsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_outlined,
                size: 18,
              ),
              onPressed: Navigator.of(context).pop
            )
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
              
                children: [
                  SizedBox(height: 5,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('lib/assets/logo.png', height: 90,),
                      SizedBox(width: 20,),
                      Text('المسابقة الرمضانية الحادية عشر\nرمضان 1447 هـ', 
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                        ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  ViewRoomsScreen()
                ],
              ),
          ),
        ],
      ),
    );
  }
}
class ViewRoomsScreen extends StatelessWidget {
  const ViewRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: RoomService.instance.watchRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rooms = snapshot.data ?? [];

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
            final nextUp =
                waitingTickets.isNotEmpty ? waitingTickets.first : null;
            final screenHeight = MediaQuery.of(context).size.height;

            if (rooms.isEmpty) {
              return const Center(
                child: Text('No rooms yet. Go to Edit to add rooms.'),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قائمة الانتظار',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                        children: waitingTickets
                            .map(
                              (t) {
                                final isNext = nextUp?.id == t.id;
                                final scheme = Theme.of(context).colorScheme;
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isNext
                                        ? scheme.tertiaryContainer
                                        : scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isNext
                                        ? Border.all(
                                            color: scheme.tertiary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isNext)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: Text(
                                            'التالي:  ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: scheme.tertiary,
                                                ),
                                          ),
                                        ),
                                      Text(
                                        t.number.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: screenHeight * 0.5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 1400
                            ? 4
                            : width >= 1000
                                ? 3
                                : width >= 650
                                    ? 2
                                    : 1;

                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: crossAxisCount == 1 ? 2.8 : 3,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return _RoomCard(room: room);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serving = room.currentTicketNumber;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.displayName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.isClosed ? 'مغلق' : 'مفتوح',
                    style: TextStyle(
                      color: room.isClosed
                          ? theme.colorScheme.error
                          : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (room.supervisorName != null &&
                      room.supervisorName!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'المشرف: ${room.supervisorName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الرقم الحالي',
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  serving?.toString() ?? '-',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

