import 'package:flutter/material.dart';

/// Diálogo que permite ao usuário escolher opções de impressão
/// como número de cópias e formato do recibo
class PrintOptionsDialog extends StatefulWidget {
  final int orderId;
  final String orderReference;
  final Function(int copies) onPrintConfirmed;
  final VoidCallback onCancel;
  
  const PrintOptionsDialog({
    super.key,
    required this.orderId,
    required this.orderReference,
    required this.onPrintConfirmed,
    required this.onCancel,
  });

  @override
  State<PrintOptionsDialog> createState() => _PrintOptionsDialogState();
}

class _PrintOptionsDialogState extends State<PrintOptionsDialog> {
  int _copies = 1;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Imprimir Recibo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedido: ${widget.orderReference}'),
          const SizedBox(height: 20),
          const Text('Quantas cópias deseja imprimir?'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _copies > 1 
                    ? () => setState(() => _copies--) 
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_copies',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _copies < 5 
                    ? () => setState(() => _copies++) 
                    : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () => widget.onPrintConfirmed(_copies),
          child: const Text('IMPRIMIR'),
        ),
      ],
    );
  }
}

/// Função auxiliar para mostrar o diálogo de opções de impressão
Future<void> showPrintOptionsDialog({
  required BuildContext context,
  required int orderId,
  required String orderReference,
  required Function(int copies) onPrintConfirmed,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PrintOptionsDialog(
        orderId: orderId,
        orderReference: orderReference,
        onPrintConfirmed: (copies) {
          Navigator.of(context).pop();
          onPrintConfirmed(copies);
        },
        onCancel: () => Navigator.of(context).pop(),
      );
    },
  );
}