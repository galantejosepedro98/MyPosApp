import 'package:essenciacompany_mobile/domain/auth_requests.dart';
import 'package:essenciacompany_mobile/domain/shop_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/custom_app_bar.dart';
import 'package:essenciacompany_mobile/presentation/component/text_input.dart';
import 'package:essenciacompany_mobile/presentation/view/scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhysicalQrView extends StatefulWidget {
  const PhysicalQrView({super.key});

  @override
  State<PhysicalQrView> createState() => _PhysicalQrViewState();
}

class _PhysicalQrViewState extends State<PhysicalQrView> {
  bool _showUserCreateForm = false;
  String? qrCode;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();
  bool _isSubmitting = false;
  String? _dialCode;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
  }

  onScan(code) async {
    Navigator.pop(context);
    print('code- $code');
    final res = await getUserFromQr(qrCode: code);
    if (res['success'] && res['data'] != null) {
      Fluttertoast.showToast(
          msg: 'QR code already used',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    setState(() {
      _showUserCreateForm = true;
      qrCode = code;
    });
    Fluttertoast.showToast(
        msg: 'Scan Successfull',
        gravity: ToastGravity.CENTER,
        backgroundColor: const Color(0xFFF36A30),
        textColor: Colors.white,
        fontSize: 16.0);
  }

  submitUserCreate() async {
    if (qrCode == null) {
      Fluttertoast.showToast(
          msg: 'QR code is required',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    if (_nameController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Name is required',
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFF36A30),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    Map<String, String?> data = {
      'name': _nameController.text,
      'email': _emailController.text.isNotEmpty ? _emailController.text : null,
      'phone': _phoneController.text.isNotEmpty
          ? '$_dialCode${_phoneController.text}'
          : null,
      'vat': _vatController.text.isNotEmpty ? _vatController.text : null,
      'code': qrCode
    };
    final res = await createQrUser(data, token: token);
    if (res['success']) {
      setState(() {
        _showUserCreateForm = false;
        qrCode = null;
      });
      _nameController.clear();
    }
    Fluttertoast.showToast(
        msg: 'User creation ${res['success'] ? 'Completed' : 'Failed'}',
        gravity: ToastGravity.CENTER,
        backgroundColor: const Color(0xFFF36A30),
        textColor: Colors.white,
        fontSize: 16.0);
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF001232),
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar.showStaffAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  if (!_showUserCreateForm)
                    Center(
                        child: GestureDetector(
                      onTap: () async {
                        // await onScan('asffasla');
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ScannerView(onScan: onScan);
                        }));
                      },
                      child: Container(
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
                          child: const SizedBox(
                              height: 160,
                              width: 160,
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 140,
                              ))),
                    ))
                  else if (_showUserCreateForm)
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextInput(
                                controller: _nameController,
                                hintText: 'Enter users name',
                              ),
                              const SizedBox(height: 10),
                              TextInput(
                                controller: _emailController,
                                hintText: 'Enter users email',
                              ),
                              const SizedBox(height: 10),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: const Color(0xFFF36A30)),
                                  ),
                                  child: InternationalPhoneNumberInput(
                                    onInputChanged: (data) {
                                      setState(() {
                                        _dialCode = data.dialCode;
                                        _countryCode = data.isoCode;
                                      });
                                    },
                                    initialValue: PhoneNumber(
                                        isoCode: _countryCode ?? 'PT'),
                                    textFieldController: _phoneController,
                                    inputBorder: InputBorder.none,
                                    selectorTextStyle: GoogleFonts.roboto(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    textStyle: GoogleFonts.roboto(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    selectorConfig: const SelectorConfig(
                                      selectorType:
                                          PhoneInputSelectorType.DIALOG,
                                    ),
                                    searchBoxDecoration: InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: GoogleFonts.roboto(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w300,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    hintText: 'Enter Phone',
                                  )),
                              const SizedBox(height: 10),
                              TextInput(
                                controller: _vatController,
                                hintText: 'Enter users vat number',
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              _isSubmitting
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF36A30),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: submitUserCreate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF36A30),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Create User',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                'Or',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    qrCode = null;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 12),
                                  color: const Color(0xFFF2500B),
                                  child: const Text(
                                    'Reset',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF001232),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            ]))
                ],
              ),
            ),
          ),
        ));
  }
}
