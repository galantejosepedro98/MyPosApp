import 'package:dotted_border/dotted_border.dart';
import 'package:essenciacompany_mobile/domain/api_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/layout/default_layout.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Option { checkIn, checkOut }

class CheckinCheckoutView extends StatefulWidget {
  final String? zone;
  final String? zoneName;
  const CheckinCheckoutView({super.key, this.zone, this.zoneName});

  @override
  State<CheckinCheckoutView> createState() => _CheckinCheckoutViewState();
}

class _CheckinCheckoutViewState extends State<CheckinCheckoutView> {
  Option _selectedOption = Option.checkIn;
  String? _ticket;

  _selectOption(Option option) {
    setState(() {
      _selectedOption = option;
    });
  }

  _onScan(ticket) async {
    setState(() {
      _ticket = ticket;
    });
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = _selectedOption == Option.checkIn
        ? await checkinRequest(token, _ticket, widget.zone)
        : await checkoutRequest(token, _ticket, widget.zone);
    if (!mounted) return;
    if (res['success']) {
      /* CustomAlert.showCustomAlert(context,
          message: res['message'] ??
              'CHECK ${_selectedOption == Option.checkIn ? 'IN' : 'OUT'} SUCCESSFUL',
          success: true); */
      Fluttertoast.showToast(
          msg: res['message'] ??
              'CHECK ${_selectedOption == Option.checkIn ? 'IN' : 'OUT'} SUCCESSFUL',
          gravity: ToastGravity.CENTER,
          backgroundColor: Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      /* CustomAlert.showCustomAlert(context,
          message: res['error'] ??
              'CHECK ${_selectedOption == Option.checkIn ? 'IN' : 'OUT'} FAILED',
          success: false); */
      Fluttertoast.showToast(
          msg: res['message'] ??
              'CHECK ${_selectedOption == Option.checkIn ? 'IN' : 'OUT'} FAILED',
          gravity: ToastGravity.CENTER,
          backgroundColor: Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
        scroll: false,
        child: Container(
            padding: const EdgeInsets.only(right: 24, top: 42, left: 24),
            height: MediaQuery.of(context).size.height,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                          onTap: () {
                            _selectOption(Option.checkIn);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: _selectedOption == Option.checkIn
                                  ? const Color(0xFFf58859)
                                  : const Color(0xFFfac3ac),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x35000000),
                                  spreadRadius: 0,
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.input,
                                      size: 60,
                                    ),
                                    Text(
                                      'Check In',
                                      style: GoogleFonts.roboto(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700),
                                    )
                                  ]),
                            ),
                          )),
                      GestureDetector(
                          onTap: () {
                            _selectOption(Option.checkOut);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            decoration: BoxDecoration(
                              color: _selectedOption == Option.checkOut
                                  ? const Color(0xFFf58859)
                                  : const Color(0xFFfac3ac),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x35000000),
                                  spreadRadius: 0,
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.output,
                                      size: 60,
                                    ),
                                    Text(
                                      'Check Out',
                                      style: GoogleFonts.roboto(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700),
                                    )
                                  ]),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/enter-code');
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x35000000),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'New Session',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
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
