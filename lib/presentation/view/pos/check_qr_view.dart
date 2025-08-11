import 'package:essenciacompany_mobile/domain/shop_requests.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:essenciacompany_mobile/presentation/component/custom_app_bar.dart';

class CheckQrView extends StatefulWidget {
  const CheckQrView({super.key});

  @override
  State<CheckQrView> createState() => _CheckQrViewState();
}

class _CheckQrViewState extends State<CheckQrView> {
  String? qrCode;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
  }

  loadData() async {
    if (qrCode != null) {
      final res = await getUserFromQr(qrCode: qrCode);
      if (res['success']) {
        final userData = res['data'];
        setState(() {
          _user = userData;
        });
      }
    }
  }

  _scan() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ScannerView(
                  onScan: (code) {
                    Navigator.pop(context);
                    setState(() {
                      qrCode = code;
                    });
                    loadData();
                  },
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar.showPosAppBar(
          context,
          title: 'Ver Saldo',
          onRefresh: loadData,
        ),
        body: SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: qrCode == null
                        ? [
                            Align(
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  onTap: _scan,
                                  child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 250,
                                        color: Color(0xFFF2500B),
                                      )),
                                ))
                          ]
                        : [
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFFF2500B),
                                        offset: Offset(5, 5),
                                      )
                                    ]),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (_user != null &&
                                          _user!['name']!.isNotEmpty)
                                        Text(
                                          '${_user!['name']}',
                                          style: const TextStyle(
                                              color: Color(0xFFF2500B),
                                              fontSize: 30),
                                          textAlign: TextAlign.start,
                                        ),
                                      if (_user != null &&
                                          _user!['email']!.isNotEmpty)
                                        Text(
                                          '${_user!['email']}',
                                          style: const TextStyle(
                                              color: Color(0xFF676767),
                                              fontSize: 16),
                                          textAlign: TextAlign.start,
                                        ),
                                      if (_user != null &&
                                          _user!['balance'] != null)
                                        Text(
                                          'Є${_user!['balance']}',
                                          style: const TextStyle(
                                              color: Color(0xFFF2500B),
                                              fontSize: 26),
                                          textAlign: TextAlign.start,
                                        )
                                    ])),
                            const SizedBox(
                              height: 20,
                            ),
                            GestureDetector(
                              onTap: _scan,
                              child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                      border: Border.all(
                                          color: const Color(0xFFF2500B),
                                          width: 4)),
                                  child: const Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Rescan QR Code',
                                      style: TextStyle(
                                          color: Color(0xFFF2500B),
                                          fontSize: 20),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                            )
                          ]))));
  }
}
