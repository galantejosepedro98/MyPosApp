import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/menu_dialog.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/pos_menu_dialog.dart';
import 'package:essenciacompany_mobile/presentation/component/pos_shop/dialogs/staff_menu_dialog.dart';
import 'package:flutter/material.dart';

class CustomAppBar {
  static showCustomAppBar(BuildContext context) {
    return AppBar(
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
                          builder: (context) => const MenuDialog());
                    },
                    icon: const Icon(Icons.more_vert),
                    color: const Color(0xFFF2500B),
                    iconSize: 30,
                  );
                },
              ),
            ],
          )),
    );
  }

  static showStaffAppBar(BuildContext context) {
    return AppBar(
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
                          builder: (context) => const StaffMenuDialog());
                    },
                    icon: const Icon(Icons.more_vert),
                    color: const Color(0xFFF2500B),
                    iconSize: 30,
                  );
                },
              ),
            ],
          )),
    );
  }

  static showPosAppBar(BuildContext context,
      {String? title,
      Function? onRefresh,
      bool showSearchbar = false,
      Function? toggleSearchbar,
      Function? onSearch,
      TextEditingController? searchController}) {
    return AppBar(
      automaticallyImplyLeading: false,
      forceMaterialTransparency: true,
      flexibleSpace: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Colors.blueGrey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!showSearchbar)
                Text(
                  title ?? 'POS',
                  style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (onRefresh != null) {
                        onRefresh();
                      }
                    },
                    icon: const Icon(Icons.loop),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                  if (showSearchbar)
                    Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.white),
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w400),
                        )),
                  IconButton(
                    onPressed: () {
                      if (toggleSearchbar != null) {
                        toggleSearchbar();
                      }
                    },
                    icon: const Icon(Icons.search),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            const PosMenuDialog(),
                      );
                    },
                    icon: const Icon(Icons.more_vert),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                ],
              )
            ],
          )),
    );
  }
}
