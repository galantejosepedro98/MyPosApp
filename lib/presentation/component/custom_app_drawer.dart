import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppDrawer {
  static showCustomAppDrawer(context,
      {Map<String, dynamic>? user, Function? onLogout}) {
    print(user);
    return Drawer(
      shadowColor: const Color(0x8FF36A30),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Image(
                        image: AssetImage('assets/logo.png'),
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        '${user['name']} ${user['l_name']}',
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFF36A30),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${user['email']}',
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              if (user != null && user['role_id'] == 6)
                Column(children: [
                  ListTile(
                    title: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/pos/tickets');
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.airplane_ticket,
                                color: Color(0xFFF36A30),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Tickets',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: const Color(0xFFF36A30),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            ])),
                  ),
                  ListTile(
                    title: GestureDetector(
                        onTap: () {},
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_drink_rounded,
                                color: Color(0xFFF36A30),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Extras',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: const Color(0xFFF36A30),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            ])),
                  ),
                  ListTile(
                    title: GestureDetector(
                        onTap: () {},
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code,
                                color: Color(0xFFF36A30),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Scan',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: const Color(0xFFF36A30),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            ])),
                  ),
                  ListTile(
                    title: GestureDetector(
                        onTap: () {},
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.file_present_rounded,
                                color: Color(0xFFF36A30),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Reports',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: const Color(0xFFF36A30),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            ])),
                  )
                ]),
              GestureDetector(
                onTap: () {
                  if (onLogout != null) onLogout();
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF36A30),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Logout',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      ],
                    )),
              )
            ],
          )),
    );
  }
}
