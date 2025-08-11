import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAlert {
  static showCustomAlert(BuildContext context,
      {bool success = false,
      String? title,
      String? subtitle,
      String message = ''}) {
    showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(
              backgroundColor: Colors.transparent,
              child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: success
                                      ? const Color(0xF2005316)
                                      : const Color(0xF2760000),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(20)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      success ? 'SUCCESS' : 'ERROR',
                                      style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 80,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (title != null)
                                      Text(
                                        title,
                                        style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    if (subtitle != null)
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 38, vertical: 22),
                              decoration: BoxDecoration(
                                  color: success
                                      ? const Color(0xF2005316)
                                      : const Color(0xF2760000),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20))),
                              child: Text(
                                message,
                                style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 25,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ]))),
            ));
  }
}
