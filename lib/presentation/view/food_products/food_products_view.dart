import 'package:dotted_border/dotted_border.dart';
import 'package:essenciacompany_mobile/domain/api_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/layout/default_layout.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodProductsView extends StatefulWidget {
  final String? zone;
  final String? zoneName;
  const FoodProductsView({super.key, this.zone, this.zoneName});

  @override
  State<FoodProductsView> createState() => _FoodProductsViewState();
}

class _FoodProductsViewState extends State<FoodProductsView> {
  String? _ticket;
  List<Map<String, dynamic>> _extras = [];

  _onScan(ticket) async {
    setState(() {
      _ticket = ticket;
    });
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await getExtrasRequest(token, _ticket);
    if (!mounted) return;
    if (res['success']) {
      final extras = res['extras'];
      setState(() {
        _extras = extras;
      });
      /* CustomAlert.showCustomAlert(context,
          message: res['message'] ?? 'SCAN SUCCESSFUL', success: true); */
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN SUCCESSFUL',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      /* CustomAlert.showCustomAlert(context,
          message: res['message'] ?? 'SCAN FAILED', success: false); */
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN FAILED',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  _handleGetUp(int id) {
    if (_extras.isEmpty) return;
    final extras = _extras;
    for (var item in extras) {
      if (item['id'] == id) {
        final qty = int.parse(item['qty']);
        item['qty'] = '${qty > 1 ? qty - 1 : qty}';
      }
    }
    setState(() {
      _extras = extras;
    });
  }

  _submitGetUp() async {
    if (_extras.isEmpty || _ticket == null || _ticket!.isEmpty) return;
    Map<String, dynamic> extras = {};
    for (var item in _extras) {
      extras['${item['id']}'] = item['qty'];
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await withdrawExtraRequest(token, _ticket, extras);
    if (res['success']) {
      setState(() {
        _extras = [];
      });
      /* CustomAlert.showCustomAlert(context,
          message: res['message'] ?? 'SCAN SUCCESSFUL',
          success: true,
          title: res['ticket']); */
      Fluttertoast.showToast(
          msg: res['message'] ?? 'SCAN SUCCESSFUL',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      /* CustomAlert.showCustomAlert(context,
          message: res['message'] ?? 'SCAN FAILED', success: false); */
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
      int qty = int.tryParse(extra['qty']) ?? 0;
      total += qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
        scroll: false,
        child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _extras.isEmpty
                      ? Image.asset(
                          'assets/icons/food.png',
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: MediaQuery.of(context).size.width * 0.65,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(children: [
                            Container(
                                decoration: BoxDecoration(
                                    boxShadow: _extras.length > 2
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x8FF36A30),
                                              spreadRadius: 0,
                                              blurRadius: 5,
                                              offset: Offset(0, 6),
                                            )
                                          ]
                                        : null,
                                    borderRadius: BorderRadius.circular(20)),
                                clipBehavior: Clip.antiAlias,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: SingleChildScrollView(
                                    child: Container(
                                        decoration: BoxDecoration(
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x8FF36A30),
                                                spreadRadius: 0,
                                                blurRadius: 5,
                                                offset: Offset(0, 6),
                                              )
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        clipBehavior: Clip.antiAlias,
                                        child: Table(
                                          border: TableBorder.all(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          children: [
                                            TableRow(
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFF36A30)),
                                                children: [
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: Text(
                                                        'Name',
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )),
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: Text(
                                                        'Amount',
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )),
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: Text(
                                                        'Get up',
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ))
                                                ]),
                                            ..._extras.map((item) {
                                              return TableRow(
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Color(
                                                              0xFFF36A30)),
                                                  children: [
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Text(
                                                          item['name'],
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )),
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Text(
                                                          '${item['qty']}',
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )),
                                                    IconButton(
                                                      onPressed: () {
                                                        _handleGetUp(
                                                            item['id']);
                                                      },
                                                      icon: const Icon(
                                                        Icons.swipe_down,
                                                      ),
                                                      color: Colors.white,
                                                      iconSize: 30,
                                                    )
                                                  ]);
                                            })
                                          ],
                                        )))),
                            const SizedBox(
                              height: 10,
                            ),
                            if (getExtrasQty() > 0)
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _submitGetUp,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF36A30),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                        'Get Up',
                                        style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ))
                          ])),
                  const SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ScannerView(
                          onScan: _onScan,
                        );
                      }));
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Scan Ticket',
                            style: GoogleFonts.roboto(
                                fontSize: 42, fontWeight: FontWeight.w200)),
                        const SizedBox(
                          height: 10,
                        ),
                        DottedBorder(
                            color: Colors.black,
                            strokeWidth: 4.0,
                            radius: const Radius.circular(30),
                            dashPattern: const [10],
                            child: const SizedBox(
                                height: 200,
                                width: 200,
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  size: 180,
                                ))),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          widget.zoneName ?? 'Door ${widget.zone}',
                          style: GoogleFonts.roboto(
                              fontSize: 40, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                ])));
  }
}
