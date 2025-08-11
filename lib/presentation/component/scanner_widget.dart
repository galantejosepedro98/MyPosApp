import 'package:flutter/material.dart';
import 'package:my_pos/my_pos.dart';

class ScannerWidget extends StatefulWidget {
  final Function(dynamic) onScan;
  const ScannerWidget({super.key, required this.onScan});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  @override
  void initState() {
    super.initState();
    _startScanner();
  }

  Future<void> _startScanner() async {
    final result = await MyPos.openScanner();
    if (result != null) {
      widget.onScan(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Scanner ativo...'),
    );
  }
}
