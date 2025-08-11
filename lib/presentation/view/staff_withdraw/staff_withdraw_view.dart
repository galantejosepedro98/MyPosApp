import 'package:essenciacompany_mobile/domain/api_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/pos_menu_dialog.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffWithdrawView extends StatefulWidget {
  const StaffWithdrawView({super.key});

  @override
  State<StaffWithdrawView> createState() => _StaffWithdrawViewState();
}

class _StaffWithdrawViewState extends State<StaffWithdrawView> {
  String? _ticket;
  List<Map<String, dynamic>> _extras = [];

  _onScan(ticket) async {
    Navigator.pop(context);
    setState(() {
      _ticket = ticket;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await getExtrasRequest(token, _ticket);
    if (!mounted) return;
    if (res['success'] == true) {
      final extras = res['extras'] ?? [];
      setState(() {
        _extras = List<Map<String, dynamic>>.from(extras);
      });
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN SUCCESSFUL',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN FAILED',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  _handleGetUp(int id, {int amount = 1}) {
    if (_extras.isEmpty) return;
    final extras = _extras;
    for (var item in extras) {
      if (item['id'] == id) {
        if (item['newQty'] == null) {
          int used = int.parse('${item['used']}');
          int remain = int.parse('${item['qty']}') - used;
          int newQty = amount;
          if (newQty >= 0 && newQty <= remain) {
            item['newQty'] = newQty;
          }
        } else {
          int used = int.parse('${item['used']}');
          int remain = int.parse('${item['qty']}') - used;
          int newQty = int.parse('${item['newQty']}') + amount;
          if (newQty >= 0 && newQty <= remain) {
            item['newQty'] = newQty;
          }
        }
      }
    }
    setState(() {
      _extras = extras;
    });
  }

  _submitGetUp() async {
    if (_extras.isEmpty || _ticket == null || _ticket!.isEmpty) return;
    int extrasSelected = 0;
    Map<String, dynamic> extras = {};
    for (var item in _extras) {
      extras['${item['id']}'] = item['newQty'] ?? 0;
      extrasSelected += int.parse('${item['newQty'] ?? 0}');
    }
    if (extrasSelected == 0) {
      Fluttertoast.showToast(
          msg: 'No extras selected',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await withdrawExtraRequest(token, _ticket, extras);
    if (res['success'] == true) {
      setState(() {
        _ticket = null;
        _extras = [];
      });
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN SUCCESSFUL',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN FAILED',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  getExtrasQty() {
    int total = 0;
    for (var extra in _extras) {
      int qty = int.tryParse('${extra['qty']}') ?? 0;
      total += qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001232),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) => const PosMenuDialog());
                      },
                      icon: const Icon(Icons.more_vert),
                      color: const Color(0xFFF2500B),
                      iconSize: 30,
                    );
                  },
                ),
              ],
            )),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ScannerView(onScan: _onScan);
                }));
                // _onScan('6824c9b566074');
              },
              child: Container(                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2500B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _ticket == null ? 'Ler Bilhete' : 'Ler Outro Bilhete',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _ticket != null && _extras.isEmpty
                    ? Center(
                        child: Text(
                          _ticket != null && _extras.isEmpty
                              ? 'Este bilhete não tem extras'
                              : 'Este bilhete não tem extras',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _extras.length,
                        itemBuilder: (context, index) {
                          final item = _extras[index];                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF002244),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Quantidade: ${(int.tryParse('${item['qty']}') ?? 0) - (int.tryParse('${item['used']}') ?? 0)}',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    color: Colors.redAccent,
                                    onPressed: () {
                                      _handleGetUp(item['id'], amount: -1);
                                    },
                                  ),
                                  Text(
                                    item['newQty'] != null
                                        ? '${item['newQty']}'
                                        : '0',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.greenAccent,
                                    onPressed: () {
                                      _handleGetUp(item['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),            if (getExtrasQty() > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ElevatedButton(
                  onPressed: _submitGetUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF36A30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                  ),
                  child: Text(
                    'Confirmar',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
