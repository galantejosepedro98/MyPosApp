import 'package:flutter/material.dart';
import '../models/pos2_event.dart';

class POS2EventSelector extends StatelessWidget {
  final List<POS2Event> events;
  final Function(POS2Event) onEventSelected;

  const POS2EventSelector({
    super.key,
    required this.events,
    required this.onEventSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione um Evento',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          if (events.isEmpty)
            const Center(
              child: Text('Nenhum evento disponível'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(event.name),
                      subtitle: event.description != null 
                          ? Text(event.description!)
                          : null,
                      trailing: event.active 
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                      onTap: event.active 
                          ? () => onEventSelected(event)
                          : null,
                      enabled: event.active,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}