import 'package:flutter/material.dart';

/// Diálogo que permite escolher quantos recibos imprimir
class POS2PrintOptionsDialog extends StatelessWidget {
  final Function(int) onOptionSelected;
  final String? invoiceId;
  final String? invoiceUrl;

  const POS2PrintOptionsDialog({
    super.key, 
    required this.onOptionSelected,
    this.invoiceId,
    this.invoiceUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impede voltar atrás com botão back
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.print,
                size: 40,
                color: Color(0xff28badf),
              ),
              const SizedBox(height: 15),
              const Text(
                'Imprimir Fatura?',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Escolha quantos exemplares:',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(context, 0, 'NÃO', Colors.red),
                  _buildOptionButton(context, 1, '1', const Color(0xff28badf)),
                  _buildOptionButton(context, 2, '2', Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, int option, String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        Navigator.of(context).pop(); // Fecha o diálogo
        onOptionSelected(option); // Chama a função de callback com a opção selecionada
      },
      child: Text(label),
    );
  }
}