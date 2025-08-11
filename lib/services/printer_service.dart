import 'package:my_pos/my_pos.dart';
import 'package:my_pos/models/my_pos_paper.dart';

class PrinterService {
  static Future<void> printCustomReceipt({
    required String posName,
    required String userName,
    required String orderId,
    required List<OrderItem> items,
    required String total,
    String? timestamp,
    String? invoiceUrl,
  }) async {
    final paper = MyPosPaper();

    try {
      // Cabeçalho
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addText(posName, fontSize: 32, alignment: PrinterAlignment.center);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addSpace(1);

      // Cliente e pedido
      paper.addText("Cliente: $userName", alignment: PrinterAlignment.left);
      if (timestamp != null && timestamp.isNotEmpty) {
        paper.addText("Tel: $timestamp", alignment: PrinterAlignment.left);
      }
      paper.addText("Pedido Nº: $orderId", alignment: PrinterAlignment.left);
      paper.addSpace(1);

      // Detalhes do pedido
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addText("DETALHES DO PEDIDO", alignment: PrinterAlignment.center);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addSpace(1);

      for (var item in items) {
        final line = "${item.name.padRight(22).substring(0, 22)} x${item.quantity.toString().padRight(2)} ${item.price}€";
        paper.addText(line, alignment: PrinterAlignment.left);
      }

      paper.addSpace(1);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addText("TOTAL: $total€", fontSize: 32, alignment: PrinterAlignment.center);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addSpace(1);

      // QR code com link da fatura
      if (invoiceUrl != null) {
        paper.addText("Aceda à sua fatura online:", alignment: PrinterAlignment.center);
        paper.addSpace(1);
        paper.addQrCode(invoiceUrl, size: 200);
        paper.addSpace(1);
      }

      // Mostrar número do pedido no fim
      paper.addText("Pedido Nº: $orderId", alignment: PrinterAlignment.center);

      paper.addCutLine();
      await MyPos.printPaper(paper);
    } catch (e) {
      print('Error printing receipt: $e');
      rethrow;
    }
  }

  static Future<void> printTestReceipt() async {
    try {
      final paper = MyPosPaper();

      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addText("ISTO É UM TESTE", fontSize: 32, alignment: PrinterAlignment.center);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("Impressão realizada com sucesso!", alignment: PrinterAlignment.center);
      paper.addSpace(1);
      paper.addText("================================", alignment: PrinterAlignment.center);
      paper.addCutLine();

      await MyPos.printPaper(paper);
    } catch (e) {
      print('Erro ao imprimir teste: $e');
      throw e;
    }
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final String price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
