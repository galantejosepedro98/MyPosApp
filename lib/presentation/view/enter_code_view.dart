import 'package:essenciacompany_mobile/domain/api_requests.dart';
import 'package:essenciacompany_mobile/presentation/component/form_widget.dart';
import 'package:essenciacompany_mobile/presentation/component/layout/default_layout.dart';
import 'package:essenciacompany_mobile/presentation/component/text_input.dart';
import 'package:essenciacompany_mobile/presentation/view/checkin_checkout/checkin_checkout_view.dart';
import 'package:essenciacompany_mobile/presentation/view/food_products/food_products_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnterCodeView extends StatefulWidget {
  const EnterCodeView({super.key});

  @override
  _EnterCodeViewState createState() => _EnterCodeViewState();
}

class _EnterCodeViewState extends State<EnterCodeView> {
  TextEditingController? codeController;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController();
  }

  _onEnter() async {
    var ins = await SharedPreferences.getInstance();
    final token = ins.getString('token');
    if (token == null || token.isEmpty || codeController == null) {
      return;
    }
    final res = await getZoneType(token, codeController?.text);
    if (res['success']) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return res['type'] == 'food'
            ? FoodProductsView(
                zone: codeController?.text,
                zoneName: res['data']['name'],
              )
            : CheckinCheckoutView(
                zone: codeController?.text,
                zoneName: res['data']['name'],
              );
      }));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Wellcome to the ${res['message']}',
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        backgroundColor: const Color(0xF2005316),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          res['message'],
          style: GoogleFonts.roboto(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        backgroundColor: const Color(0xF2760000),
      ));
    }
  }

  @override
  void dispose() {
    codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(
              image: const AssetImage('assets/logo.png'),
              width: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.fitWidth,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              'Enter Code',
              style:
                  GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w400),
            ),
            const SizedBox(
              height: 24,
            ),
            FormWidget(
              children: [
                TextInput(
                  controller: codeController ?? TextEditingController(),
                  hintText: 'Enter Code',
                ),
                const SizedBox(
                  height: 26,
                ),
                GestureDetector(
                  onTap: _onEnter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF36A30),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Enter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
