import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppConstants {
  static GlobalKey bottomBarKey = GlobalKey();
  static ValueNotifier<int> badgeVal = ValueNotifier(0);
  static String authToken = "";
  static String deviceToken = "";
  static String name = "";

  static funcShowSnackBar(BuildContext context, String messageStr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 200,
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        content: Text(messageStr),
      ),
    );
  }

  static void showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
