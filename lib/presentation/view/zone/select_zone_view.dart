import 'package:essenciacompany_mobile/presentation/component/select_button.dart';
import 'package:essenciacompany_mobile/presentation/view/checkin_checkout/checkin_checkout_view.dart';
import 'package:essenciacompany_mobile/presentation/view/enter_code_view.dart';
import 'package:essenciacompany_mobile/presentation/view/food_products/food_products_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectZoneView extends StatefulWidget {
  const SelectZoneView({super.key});

  @override
  State<SelectZoneView> createState() => _SelectZoneViewState();
}

class _SelectZoneViewState extends State<SelectZoneView> {
  final TextEditingController _codeController = TextEditingController();

  void _onEnter({foodZone = false}) {
    if (_codeController.text.isEmpty) {
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return foodZone
          ? FoodProductsView(
              zone: _codeController.text,
            )
          : CheckinCheckoutView(
              zone: _codeController.text,
            );
    }));
  }

  _selectCheckInCheckOut() {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EnterCodeView();
    }));
  }

  _selectFoodProducts() {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EnterCodeView();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Text(
                'Your Zone',
                style: GoogleFonts.roboto(
                    fontSize: 42, fontWeight: FontWeight.w200),
              ),
              const SizedBox(
                height: 46,
              ),
              SelectButton(
                  icon: 'assets/icons/door-open.png',
                  onTap: _selectCheckInCheckOut),
              const SizedBox(
                height: 26,
              ),
              const Divider(
                color: Color(0xFFF36A30),
                thickness: 2,
                indent: 40,
                endIndent: 40,
              ),
              const SizedBox(
                height: 26,
              ),
              SelectButton(
                  icon: 'assets/icons/food.png', onTap: _selectFoodProducts),
            ])));
  }
}
